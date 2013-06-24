class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :confirmed_at
  attr_accessible :name, :time_zone
  has_many :surveys

  validates_inclusion_of :time_zone, in: ActiveSupport::TimeZone.zones_map(&:name)
  validates_presence_of :name
  #bring in collaborators

  def published_survey_count
    self.published_surveys.count
  end

  def pref_us_time_format
    ActiveSupport::TimeZone.us_zones.map{|z|z.name}.include?(time_zone)
  end

  #should be renamed to available surveys.
  def published_surveys
    sids = Collaborator.where(:email => self.email) #all the surveys this person has access to.
    u = self #a ref for self to use in query.
    Survey.where{(status == true) & ((user_id == u.id) | (id.in(sids.select{survey_id})))}
  end

end
