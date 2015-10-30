class CoursesController < ApplicationController
  include CoursesHelper
  before_filter :check_for_cancel, :only => [:create, :update]

	def index
    @courses = Course.all
    @courses_ta = Hash.new 
    internal_courses_ta = Hash.new  # internal usage
    
    @courses.each do |course|
      tadata = Student.where(:course_assigned => course.id)  # This will return one list
      @courses_ta[course.id] = tadata

      internal_courses_ta[course.id] = []
      tadata.each_index do |i|
        internal_courses_ta[course.id][i] = tadata[i].attributes
      end

      
    end
    @SlotStatus = getSlotStatusForAllCourses(internal_courses_ta)
    #debugger
  end

  #  /courses/new
  def new
  # default: render 'new' template
    @course = Course.new
  end


  # POSt /courses
  def create
    @course = Course.create!(params[:course])
    #debugger
    flash[:notice] = "#{@course.name} was successfully created."
    redirect_to courses_path
    end

  # GET /courses/:id
  def show
    @course = Course.find(params[:id])
  end
  
  # GET /courses/:id/edit
  def edit
    @course = Course.find params[:id]
  end
  

  # PATCH /courses/:id
  def update
    @course = Course.find params[:id]
    @course.update_attributes!(params[:course])
    flash[:notice] = "#{@course.name} was successfully updated."
    redirect_to courses_path
  end

  def check_for_cancel
    if params[:commit] == "Cancel"
      redirect_to courses_path
    end
  end

  # DELETE /courses/:id
  def destroy
    @course = Course.find(params[:id])
    respond_to do |format|
      format.html {redirect_to courses_url, notice: "Course #{@course.name} was successfully destroyed"}
      format.json {head :no_content}
    end
  end

  def select_new_ta
    @course = Course.find(params[:id])
    @students = Student.where(status: Student::UNDER_REVIEW)
  end

  def assign_new_ta
    id = params[:id]
    @course = Course.find(id)
    if params[:ids]
      new_tas = params[:ids].keys
      if not new_tas.empty?
        new_tas.each do |ta_id|
          @student = Student.find(ta_id)
          @student.course_assigned = @course.id
          @student.status = Student::TEMP_ASSIGNED
          @student.save!
        end
      end
    end
    flash[:notice] = "New TA assigned for #{@course.name}"
    redirect_to courses_path
  end

  # Email  
  def email_ta_notification
    @student = Student.find(params[:ta_id])
    @student.status = Student::EMAIL_NOTIFIED
    @student.save!
    @user = User.find_by(:uin => @student.uin)
    ## Sent mail to @user
    UserNotifier.send_ta_notification(@user).deliver
    flash[:notice] = "A Notification Email has been sent to #{@student.fullName()}: #{@user.email}"
    redirect_to courses_path
  end

  # Confirm courses/confirm_ta/:id/:ta_id
  def confirm_ta
    @student = Student.find(params[:ta_id])
    @student.status = Student::ASSIGNED
    @student.save!
    flash[:notice] = "TA #{@student.fullName()} is confirmd!"
    redirect_to courses_path
  end

  # Delete courses/delete_ta
  def delete_ta
    @course = Course.find(params[:id])
    @student = Student.find(params[:ta_id])
    @student.status = Student::UNDER_REVIEW
    @student.course_assigned = 0
    @student.save!

    flash[:notice] = "TA #{@student.fullName()} is deleted for #{@course.name}"
    redirect_to courses_path
  end
end
