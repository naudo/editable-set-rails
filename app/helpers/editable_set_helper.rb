module EditableSetHelper
  
  [:form_for, :fields_for, :form_remote_for, :remote_form_for].each do |meth|
    src = <<-end_src
      def editable_#{meth}(object_name, *args, &proc)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options.update(:builder => EditableFormBuilder)
        #{meth}(object_name, *(args << options), &proc)
      end
    end_src
    module_eval src, __FILE__, __LINE__
  end
  

  class EditableFormBuilder < ActionView::Helpers::FormBuilder
    
=begin rdoc
  The Following:
    editable_span :patient, [appointment, index, :meet_for], { :type => :select, :options => (1..6).map{|i| i*15 }.to_json }

  Outputs:
    %label{ :for => "patient_appointments_attributes_#{index}_meet_for" } Meet For
    %span{ :id => "patient_appointments_attributes_#{index}_meet_for", :name => "patient[appointments_attributes][#{index}][meet_for]", 
                                                                       :type => :select, 
                                                                       :options => (1..6).map{|i| i*15 }.to_json }= appt.meet_for
    
  Acceptable Formats:
    editable_span :patient, :full_name
    editable_span :patient, [@patient.address, :street1] # for use with one-to-one, must define :singular => true
    editable_span :patient, [appointment, index, :meet_for] # for use with one-to-many, inside of loop, i.e. @patient.appointments.each_with_index do |appointment, index|
    
  Options:
    # Define your own value
    :value => @patient.birthday.strftime(...)
    
    # No label
    :label => false
    
    # Define the type, :text is default
    :type => :select
    
    # For one-to-one associations
    :singular => true

=end  
  
  def editable_span(object_name, method_and_or_association, opts={})
    
    if method_and_or_association.class == Symbol
      method = method_and_or_association
    else # assume it's an array containing associations
      method = method_and_or_association.pop
      has_association = true unless method_and_or_association.empty?
      association = method_and_or_association.shift        
      unless association.nil? # This could happen if the records don't yet exist
        association_name = association.class.class_name.underscore
        association_name = association_name.pluralize unless opts[:singular] == true
      end
      index = method_and_or_association.to_s
      
      # NEEDS to compensate for deeply nested attrs, i.e. @patient.employer.address
    end
    
    # Define our options
    opts[:type]   ||= :text
    opts[:label]  ||= method.to_s.humanize unless opts[:label] == false
    
    value = opts.delete :value # returns the value
    
    # Create the id attribute
    tag_id = "#{object_name}"
    tag_id << "_#{association_name}_attributes" unless association_name.nil? || association_name.blank?
    tag_id << "_#{index}" unless index.nil? || index.blank?
    tag_id << "_#{method}"

    # Create the name_attribute
    tag_name = "#{object_name}"
    tag_name << "[#{association_name}_attributes]" unless association_name.nil? || association_name.blank?
    tag_name << "[#{index}]" unless index.nil? || index.blank?
    tag_name << "[#{method}]"
    
    # Keep the hidden fields hidden and remove the label
    if opts[:type].to_sym == :hidden
      opts[:style] ||= ""
      opts[:style] += " display: none; "
      opts[:label] = nil
    end
    
    # Create the label tag
    if opts[:label]

      label = @template.content_tag(:label, {:for => tag_id}) do
        opts[:label]
      end
    end
    opts.delete :label # Don't want to pass that as an attribute
    
    # Create the span tag
    span = @template.content_tag(:span, {:id => tag_id, :name => tag_name}.merge(opts)) do

      if has_association
        value ? value : association.send(method) unless association.nil?
      else
        object = @template.instance_variable_get("@#{object_name.to_s}")
        value ? value : object.send(method)
      end
    end
    
    "#{label} #{span}"
  end


  end
end
