gem 'activerecord'

module CoHack
  module DatetimeHack
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def datetime_hack(*attributes)
        
        send :define_method, "combine_to_datetime".to_sym do |date_string, time_string|
          date_string ||= ''
          time_string ||= ''
          time_string = "00:00" if time_string == "0"
          
          time_string.insert(-3, ":") if time_string.length < 5 and time_string.length > 2
          time_string.squeeze!(":")
          
          if time_match = time_string.match(/^([0-9][0-9](\:)*[0-9][0-9])$/)
            hour, minutes = time_match[0].split(":")
          end
          
          month, day, year = date_string.split('/')
          
          my_str = "#{day}/#{month}/#{year} #{hour}:#{minutes} #{Time.zone.now.strftime("%z")}"
          res = my_str.to_datetime rescue nil
          res
        end
        
        attributes.each do |attribute|
          attribute_array = attribute.to_s.split("_")
          attribute_array.pop
          attribute_base = attribute_array.join("_")
          
          send :define_method, "#{attribute_base}_date=".to_sym do |date_value|
            instance_variable_set("@#{attribute_base}_date", date_value)
          end
          
          send :define_method, "#{attribute_base}_date".to_sym do
            date_value = instance_variable_get("@#{attribute_base}_date")
            if !date_value
              instance_variable_set("@#{attribute_base}_date", (self.send(attribute.to_sym).to_date.to_s rescue nil))
              date_value = instance_variable_get("@#{attribute_base}_date")
            end
            date_value
          end
          
          send :define_method, "#{attribute_base}_time=".to_sym do |time_value|
            instance_variable_set("@#{attribute_base}_time", time_value ) 
          end
          
          send :define_method, "#{attribute_base}_time".to_sym do
            time_value = instance_variable_get("@#{attribute_base}_time")
            if !time_value
              instance_variable_set("@#{attribute_base}_time", (self.send(attribute.to_sym).strftime("%H%M") rescue nil ))
              time_value = instance_variable_get("@#{attribute_base}_time")
            end
            time_value
          end
          
          send :define_method, "#{attribute_base}_time_is_valid?" do
            self.errors.add(attribute, "is not valid, malformed, or is missing") if self.send(attribute).nil?
          end
          
          send :define_method, "combine_#{attribute}".to_sym do
            date_value = instance_variable_get("@#{attribute_base}_date")
            time_value = instance_variable_get("@#{attribute_base}_time")
            
            self.send("#{attribute}=", combine_to_datetime(date_value, time_value))
          end
          
          self.class_eval do
            before_validation "combine_#{attribute}"
            validate "#{attribute_base}_time_is_valid?"
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, CoHack::DatetimeHack
