class ContactsController < ApplicationController
  def get_photo
    @image_data = Contact.find(params[:id], :conditions => ["ward_id IN (?)", current_user.contact.ward.stake.wards]).photo
    @image = @image_data.data
    send_data(@image,   :type => @image_data.content_type,
                        :filename => @image_data.filename,
                        :disposition => 'inline')
  end

  # TODO move to feed?
  # GET /contacts/in_progress/datetime
  def in_progress
    #http://railsforum.com/viewtopic.php?pid=104833
    date = Time.at(params[:id].to_i)
    @contacts = Contact.find(:all, :conditions => { :created_at => date .. Time.now })

    result = {}
    result[:status] = 200
    result[:found] = (@contacts != nil)
    result[:contacts] = @contacts

    respond_to do |format|
        format.html # in_progress.html.erb
        format.json { render :json => @result }
        format.xml  { render :xml => @result }
    end
  end

  # GET /contacts
  # GET /contacts.xml
  def index
    @bishopric = bishopric
    @leadership = leadership
    @contacts = members 

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contacts }
    end
  end

  def index
    @bishopric = bishopric
    @leadership = leadership
    @contacts = members 
    respond_to do |format|
      format.html # debug.html.erb
      format.xml  { render :xml => @contacts }
    end
  end

  # GET /contacts/1
  # GET /contacts/1.xml
  def show
    @contact = Contact.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @contact }
    end
  end

  # GET /contacts/new
  # GET /contacts/new.xml
  def new
    @contact = Contact.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @contact }
    end
  end

  # GET /contacts/1/edit
  def edit
    @contact = Contact.find(params[:id])
  end

  # POST /contacts
  # POST /contacts.xml
  def create
    @contact = Contact.new(params[:contact])

    respond_to do |format|
      if @contact.save
        flash[:notice] = 'Contact was successfully created.'
        format.html { redirect_to(@contact) }
        format.xml  { render :xml => @contact, :status => :created, :location => @contact }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    @contact = Contact.find(params[:id])

    respond_to do |format|
      if @contact.update_attributes(params[:contact])
        flash[:notice] = 'Contact was successfully updated.'
        format.html { redirect_to(@contact) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contacts/1
  # DELETE /contacts/1.xml
  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy

    respond_to do |format|
      format.html { redirect_to(contacts_url) }
      format.xml  { head :ok }
    end
  end

  private
    #TODO move to model
    def bishopric
      return Contact.find(:all, :conditions => ["callings.name LIKE ? AND ward_id = ?", 'Bishop%', current_user.contact.ward], :include => [:callings, :photo], :order => 'callings.name') unless @bishopric
    end

    def leadership
      return Calling.find(:all, :conditions => ["callings.name NOT LIKE ? AND wards.id = ?", 'Bishop%', current_user.contact.ward], :include => [{:contacts => :ward}, :calling_type], :order => :calling_type_id) unless @leadership 
      #return Contact.find(:all, :conditions => ["callings.name IS NOT NULL AND callings.name NOT LIKE ? AND ward_id = ?", 'Bishop%', current_user.contact.ward], :include => [:callings]) unless @leadership 
    end

    def members
      #return (current_user.contact.ward.find(:include => [:contacts => :photo], :order => ['contact.address_line_1, contact.address_line_2, contact.first']).contacts - bishopric) unless @contacts
      return (Contact.find(:all, :conditions => {:ward_id => current_user.contact.ward}, :include => [:photo, :address_group], :order => ['address_group_id, address_line_1, address_line_2, first']) - @bishopric) unless @contacts
    end

    def same_complex?
      puts 'todo'
    end
    def same_apartment?
      puts 'todo'
    end
end
