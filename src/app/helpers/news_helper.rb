module NewsHelper
  def page_navigation
    output = "<ul class='page-navigation'>"
    
    output << "<li>"
    if @page == 1
      output << "&laquo; nieuwer"
    else
      output << link_to("&laquo; nieuwer", {:action => 'page', :page_number => (@page - 1)}, :title => 'Ga een pagina verder')
    end
    output << "</li>"
    
    1.upto(@pages) { |i|
      output << "<li>"
      if @page == i
        output << i.to_s
      else
        output << link_to(i, {:action => 'page', :page_number => i}, :title => "Ga naar pagina #{i}")
      end
      output << "</li>"
    }

    output << "<li>"
    if @page == @pages
      output << "ouder &raquo;"
    else
      output << link_to("ouder &raquo;", {:action => 'page', :page_number => (@page + 1)}, :title => 'Ga een pagina terug')
    end
    output << "</li>"
    
    output << "</ul>"
    output
  end
end
