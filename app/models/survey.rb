class Survey < ActiveRecord::Base
  belongs_to :user
  attr_accessible :description, :status, :title, :public
  has_many :reports, :dependent => :destroy
  has_many :questions, :dependent => :destroy
  has_one  :area, :dependent => :destroy
  has_many :collaborators, :dependent => :destroy
  self.include_root_in_json = false
  require 'open-uri'

  after_create(:on => :create) do
    if !self.user.nil?
      self.time_zone = self.user.time_zone #test hack
    end
    self.save
  end

  def getS3Connect
    #prep a new Fog Connection
    connection = Fog::Storage.new({:provider => 'AWS',:aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],:aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']})
  end

  def getBucket(connection)
    #use an active Fog connection to get this bucket
    connection.directories.get(ENV['USER_ASSETS_BUCKET'])
  end

  def postSpec(spec)
      #Post the spec to our MapFish Server.3 retries allowed.
      connection = Excon.new(ENV["PRINT_SERVER_ENDPOINT"])
      connection.request(:idempotent => true)
      response = connection.post(
        :body => URI.encode_www_form("spec" => spec),
        :headers => { "Content-Type" => "application/x-www-form-urlencoded" }
      )
      #MapFish passes back the url of the PDF.
      js = JSON.parse(response.body)
      return js['getURL']
  end

  def getFilepath(name)
    bucket = getBucket(getS3Connect()) #get active connection
    obj = bucket.files.get(name) #find this file
    expires_in = Time.now + 10.minutes #prep a new expiry time
    return obj.url(expires_in) #return fresh new url with expiry
  end

  def last_updated_by
    if reports.exists?
      reports.order("updated_at DESC").first.user
    else
      return nil
    end
  end

  def getWallmapURL

      if wallmap_url.nil?
        puts "saving new!!!"
        ac = ActionController::Base.new()

        payload = ac.render_to_string :file =>'surveys/wallmap.json.jbuilder', :locals => {:survey => self}
      
        #Use for testing.
        #render :text => payload

        path_to_pdf = postSpec(payload)


        filename = "#{self.id}_#{self.slugify_title}_wallmap_#{Time.now.to_i}.pdf"


        bucket = getBucket(getS3Connect())
        file = bucket.files.create(
          :key    => filename,
          :body   => open(path_to_pdf).read,
          :public => false
        )

        self.wallmap_url = filename
        self.save
      else
        puts "RETRIEVING!!!"
      end

      return getFilepath(self.wallmap_url)
  end

  def getAtlasURL()
      if atlas_url.nil?
        puts "saving new!!!"
        ac = ActionController::Base.new()

        payload = ac.render_to_string :file =>'surveys/atlas.json.jbuilder', :locals => {:survey => self}
      
        #Use for testing.
        #render :text => payload

        path_to_pdf = postSpec(payload)


        filename = "#{self.id}_#{self.slugify_title}_atlas_#{Time.now.to_i}.pdf"


        bucket = getBucket(getS3Connect())
        file = bucket.files.create(
          :key    => filename,
          :body   => open(path_to_pdf).read,
          :public => false
        )

        self.atlas_url = filename
        self.save
      else
        puts "RETRIEVING!!!"
      end

      return getFilepath(self.atlas_url)
  end

  def actual_questions
      questions.order(:index)
  end

  def field_questions
      actual_questions.offset(1)
  end

  def types_used
      field_questions.pluck(:form).uniq
  end

  def map_form
    #cache this
    actual_questions.first.form
  end

  def map_has_points
    #cache this
    map_form!='geo_point'
  end

  def answer_map
    actual_questions.map{|q| {:label => q.label,:answer => q.retrieval_map} }
  end

  def total_respondent_count
    rids = reports
    theanswers = Spresult.where{report_id.in(rids.select{id})}.count
  end

  def all_finished_reports
    reports.where(:status => true)
  end

  def serializing_answer_map
    ahash = Hash.new
    actual_questions.each{|q| ahash[q.id] = q.symbol_retrieval_map }
    return ahash
  end

  def total_finished_respondent_count
    rids = all_finished_reports
    theanswers = Spresult.where{report_id.in(rids.select{id})}.where{status == true}.count
  end

  def geo_type
    hash = {"geo_point" => "Point","geo_polygon" => "Area","geo_line" => "Pathway"}
    hash[self.map_form]
  end

  def geojson_type
    hash = {"geo_point" => "Point","geo_polygon" => "Polygon","geo_line" => "LineString"}
    hash[self.map_form]
  end

  def all_entries
    rids = reports
    Spresult.where{report_id.in(rids.select{id})}.where(:status => true).order{spresult.answers.question_id}.includes(:answers => [:points])
  end

  def slugify_title
    self.title.downcase.gsub(/[^a-z1-9]+/, '_').chomp('_')
  end

  def location
    return "#{(self.area.city || "N/A")}, #{(self.area.country || "N/A")}"
  end

  def producePagesForPDF(forAtlas)
    pages = Array.new

    first = {
            :bbox => XGEOServices.GetBoxInM(self),
            :mapTitle => "CaerusGEO",
            :survey_info => "#{title}",
            :atlas_info => "",
            :rotation => 0,
            :reportTitle => title 
        }

    pages << first

    if forAtlas and area.grids.count > 1
      others = XGEOServices.ProduceGridPages(self)

      others.each do |grid_page|
        newhash = {
              :bbox => grid_page[:bbox],
              :mapTitle =>  "",
              :comment => "",
              :survey_info => "#{title}",
              :atlas_info => "",
              :rotation => 0,
              :slabel => grid_page[:label]
          }
        pages << newhash
      end
    end


    return pages

  end

  def produceBaseLayerforPDF
    base = { :baseURL => "http://tile.openstreetmap.org/",
            :type => "Osm",
            :maxExtent => [-20037508.3392,-20037508.3392,20037508.3392,20037508.3392],
            :tileSize => [256,256],
            :resolutions => [156543.0339,78271.51695,39135.758475,19567.8792375,9783.93961875,4891.969809375,2445.9849046875,1222.99245234375,611.496226171875,305.7481130859375,152.87405654296876,76.43702827148438,38.21851413574219,19.109257067871095,9.554628533935547,4.777314266967774,2.388657133483887,1.1943285667419434,0.5971642833709717],
            :extension => "png"
          }
      return base
  end

  def produceVectorLayersforPDF(forAtlas)
    layers = []
    layers << self.produceBaseLayerforPDF

    base_grids = area.grids.includes(:ne,:sw).map do |grid|
      {:bbox => XGEOServices.GetGridInM(grid), :label_square => XGEOServices.GetLabelBox(grid), :label => grid.name, :index => grid.index}
    end

    styles_section = Hash.new
    features = Array.new

    strokewidth = forAtlas ? 1.5 : 2

    styles_section[:grid] = {
                    :fillColor => "#777777",
                    :fillOpacity => 0,
                    :strokeColor => "#000000",
                    :strokeOpacity => 1,
                    :strokeWidth => strokewidth
                }

    fontsize = forAtlas ? (56/base_grids.count).to_i : 18
    thecount = base_grids.count
    if forAtlas
      case thecount
        when 1
          fontsize = 24
        when 2
          fontsize = 17
      end
    end

    base_grids.each do |grid|
      styles_section[grid[:index]] = {
            :label => grid[:label],
            :fontColor => "#ffffff",
            :fontWeight => "bold",
            :fontSize => fontsize,
            :fillColor => "#000000"
      }

      polygon = {:type => "Feature",
                        :id => "grid",
                        :properties => {:_style => "grid"},
                        :geometry => {:type => "Polygon",:coordinates => [
                            grid[:bbox]
                        ]}
                }
      label = {
                        :type => "Feature",
                        :id => grid[:index],
                        :properties => {:_style => grid[:index]},
                        :geometry => {:type => "Polygon", :coordinates => [
                            grid[:label_square]
                        ]}
                    }
      features << polygon
      features << label
    end


    vector =   {
            :type => "Vector",
            :styles => styles_section,
            :styleProperty => "_style",
            :geoJson => {:type => "FeatureCollection",:features => features}
        }


    layers << vector
    return layers
  end

  def as_json(options={})
    super(:except => [:atlas_url,:wallmap_url,:public,:id,:created_at,:updated_at,:_id,:area_id,:title,:description,:status,:user_id], 
          :include => { :area => {:include => {:ne => {:except => [:location_id,:location_type,:location_subtype,:created_at,:updated_at,:id]},:sw => {:except => [:location_id,:location_type,:location_subtype,:created_at,:updated_at,:id]},:grids =>  {
                                      :except => [:id,:created_at,:updated_at,:area_id,:index],
                                      :include => {:ne => {:except => [:location_id,:location_type,:location_subtype,:created_at,:updated_at,:id]},
                                                :sw=> {:except => [:location_id,:location_type,:location_subtype,:created_at,:updated_at,:id]}}
                                    } ,
                                  },:except => [:city,:country,:id,:thumbnail,:created_at,:updated_at,:survey_id]},
                        
                      }
         )
  end

end
