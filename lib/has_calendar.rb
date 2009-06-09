module SimplesIdeias
  module Calendar
    module ActionView
      def calendar(options={}, &block)
        @options = options = {
          :year => Date.today.year,
          :month => Date.today.month,
          :today => nil,
          :events => nil,
          :field => :created_at,
          :header_format => :day_of_week,
          :caption_format => "%B %Y",
          :id => "calendar"
        }.merge(options)
        
        # If provided, group events by the day of their occuring
        @records = group_events(options[:events], options[:field])
        
        @records.each { |key, value| logger.debug("#{key}: #{Date.jd(key)} => #{value.size} events") }
        
        # Get the list of all days which we will present in the calendar
        days = days_for_calendar
      
        # Building the calendar
        contents = content_tag(:table, :id => options[:id], :class => 'monthly calendar') do
          rows = ""
          days.in_groups_of(7, "") do |week_days|
            rows << content_tag(:tr, week_days.inject("") { |cols, day| cols << html_for_day(day, &block) })
          end
          table_caption + table_header + rows
        end
        
        # If a block is given, replace it by the calendar
        concat(contents) if block_given?
        
        # Or maybe the user just wanna render a simple calendar
        contents
      end
      
      def table_caption
        content_tag(:caption, I18n.l(Date.civil(@options[:year], @options[:month]), :format => @options[:caption_format]))
      end
      
      # Create the calendar table header consisting of seven th fields in a row
      def table_header
        first_day_of_week = Date.today.beginning_of_week
        content_tag(:thead) do
          content_tag(:tr) do
            (0..6).collect { |i| content_tag(:th, l(first_day_of_week + i, :format => @options[:header_format])) }.to_s
          end
        end
      end
      
      def days_for_calendar
        base_day = Date.civil(@options[:year], @options[:month], 1)
        (base_day.beginning_of_week..base_day.end_of_month.end_of_week).to_a
      end
      
      
      def html_for_day(day, &block)
        col_options = { :class => 'day' }
        events_html = ""
        
        if block_given? && !day.blank?
          events_html = @records ? capture(day, @records[day.jd], &block) : capture(day, &block)
        end
        
        unless day.blank?
          col_options[:class] << ' today' if Date.today == day
          col_options[:class] << ' weekend' if [0,6].include?(day.wday)
          col_options[:class] << ' marked' if @options[:marked] == day
          col_options[:class] << ' different_month' if day.month != @options[:month]
          col_options[:class] << ' events' unless events_html.blank?
        end
        
        content_tag(:td, col_options) do
          content_tag(:div, I18n.l(day, :format => "%d"), :class => 'day_indicator') + events_html
        end
      end
      
      def group_events(events, field)
        events.group_by { |event| event.send(field).to_date.jd } if events
      end
      
    end
  end
end