module NewsHelper
  def page_navigation
    output = "<ul class='page-navigation'>".html_safe

    output << "<li>".html_safe
    if @page == 1
      output << "&laquo; nieuwer".html_safe
    else
      output << link_to("&laquo; nieuwer".html_safe, {:action => 'page', :page_number => (@page - 1)}, :title => 'Ga een pagina verder')
    end
    output << "</li>".html_safe

    1.upto(@pages) { |i|
      output << "<li>".html_safe
      if @page == i
        output << i.to_s
      else
        output << link_to(i, {:action => 'page', :page_number => i}, :title => "Ga naar pagina #{i}")
      end
      output << "</li>".html_safe
    }

    output << "<li>".html_safe
    if @page == @pages
      output << "ouder &raquo;".html_safe
    else
      output << link_to("ouder &raquo;".html_safe, {:action => 'page', :page_number => (@page + 1)}, :title => 'Ga een pagina terug')
    end
    output << "</li>".html_safe

    output << "</ul>".html_safe
    output
  end
end
