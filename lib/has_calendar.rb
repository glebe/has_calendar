module HasCalendar

  def calendar(options={}, &block)
    @options = {
      :year => Date.today.year,
      :month => Date.today.month,
      :events => nil,
      :field => :created_at,
      :header_format => "%a",
      :caption_format => "%B %Y",
      :id => nil,
      :allow_user_date_select => true,
      :marked => Array.new
    }.merge(options)

    # Allow parametre overides
    if @options[:allow_user_date_select]
      @options[:month] = params[:month].to_i if params[:month]
      @options[:year] = params[:year].to_i if params[:year]
    end

    # If provided, group events by the day of their occuring, else set a blank array
    @records = group_events(@options[:events], @options[:field]) || Array.new

    @records.each { |key, value| logger.debug("#{key}: #{Date.jd(key)} => #{value.size} events") }

    # Get the list of all days which we will present in the calendar
    days = days_for_calendar

    # Building the calendar
    contents = content_tag(:table, :id => @options[:id], :class => 'calendar') do
      rows = ""
      days.in_groups_of(7, "") do |week_days|
        rows << content_tag(:tr, week_days.inject("") { |cols, day| cols << html_for_day(day, &block) })
      end
      table_header + rows + table_footer
    end

    # If a block is given, replace it by the calendar
    concat(contents) if block_given?

    # Or maybe the user just wanna render a simple calendar
    contents
  end

  private

  def group_events(events, field)
    events.group_by { |event| event.send(field).to_date.jd } if events
  end

  def days_for_calendar
    base_day = Date.civil(@options[:year], @options[:month], 1)
    (base_day.beginning_of_week..base_day.end_of_month.end_of_week).to_a
  end

  def html_for_day(day, &block)
    col_options = { :class => 'day' }
    events_html = ""

    if block_given? && !day.blank?
      events_html = !@records.blank? ?
        capture(day, (@records[day.jd] || Array.new), &block) :
        capture(day, &block)
    end

    unless day.blank?
      col_options[:class] << ' today' if Date.today == day
      col_options[:class] << ' weekend' if [0,6].include?(day.wday)
      col_options[:class] << ' sunday' if day.wday == 0
      col_options[:class] << ' marked' if @options[:marked].include?(day.to_s)
      col_options[:class] << ' different_month' if day.month != @options[:month]
      col_options[:class] << ' events' unless events_html.blank?
    end

    content_tag(:td, col_options) do
      content_tag(:div, I18n.l(day, :format => "%d"), :class => 'day_indicator') + events_html
    end
  end

  # Create the calendar table header consisting of seven th fields in a row
  def table_header
    first_day_of_week = Date.today.beginning_of_week
    content_tag(:thead) do
      content_tag(:tr) do
        (0..6).collect do |i|
          classes = 'day_name'
          classes << ' weekend' if [5,6].include?(i)
          classes << ' sunday' if i == 6
          content_tag(:th, l(first_day_of_week + i, :format => @options[:header_format]), :class => classes)
        end.to_s
      end
    end
  end

  def table_footer
    content_tag(:tr, :class => 'footer') do
      content_tag(:th, :colspan => 2, :class => 'previous_month') do
        link_to('&laquo; Previous Month', :month => previous_month, :year => previous_year) if @options[:allow_user_date_select]
      end +
      content_tag(:th, table_caption.to_s, :colspan => 3, :class => 'caption') +
      content_tag(:th, :colspan => 2, :class => 'next_month') do
        link_to('Next Month &raquo;', :month => next_month, :year => next_year) if @options[:allow_user_date_select]
      end
    end
  end

  def table_caption
    content_tag(:div, I18n.l(Date.civil(@options[:year], @options[:month]), :format => @options[:caption_format])) if @options[:caption_format]
  end

  def previous_month
    previous_month = @options[:month] - 1
    previous_month = 12 if previous_month < 1
    previous_month
  end

  def next_month
    next_month = @options[:month] + 1
    next_month = 1 if next_month > 12
    next_month
  end

  def previous_year
    previous_year = @options[:year]
    previous_year = previous_year - 1 if @options[:month] == 1
    previous_year
  end

  def next_year
    next_year = @options[:year]
    next_year = next_year + 1 if @options[:month] == 12
    next_year
  end

end
