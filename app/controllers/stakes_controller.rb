class StakesController < ApplicationController
  # GET /stakes
  # GET /stakes.xml
  def index
    @stakes = Stake.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @stakes }
    end
  end

  # GET /stakes/1
  # GET /stakes/1.xml
  def show
    @stake = Stake.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @stake }
    end
  end

  # GET /stakes/new
  # GET /stakes/new.xml
  def new
    @stake = Stake.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @stake }
    end
  end

  # GET /stakes/1/edit
  def edit
    @stake = Stake.find(params[:id])
  end

  # POST /stakes
  # POST /stakes.xml
  def create
    @stake = Stake.new(params[:stake])

    respond_to do |format|
      if @stake.save
        flash[:notice] = 'Stake was successfully created.'
        format.html { redirect_to(@stake) }
        format.xml  { render :xml => @stake, :status => :created, :location => @stake }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @stake.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /stakes/1
  # PUT /stakes/1.xml
  def update
    @stake = Stake.find(params[:id])

    respond_to do |format|
      if @stake.update_attributes(params[:stake])
        flash[:notice] = 'Stake was successfully updated.'
        format.html { redirect_to(@stake) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @stake.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /stakes/1
  # DELETE /stakes/1.xml
  def destroy
    @stake = Stake.find(params[:id])
    @stake.destroy

    respond_to do |format|
      format.html { redirect_to(stakes_url) }
      format.xml  { head :ok }
    end
  end
end
