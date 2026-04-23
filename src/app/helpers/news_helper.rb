# encoding: utf-8
module NewsHelper
  def page_navigation
    output = "<ul class='page-navigation'>"

    output << "<li>"
    output << if @page == 1
                "« nieuwer"
              else
                link_to("« nieuwer", { action: 'page', page_number: (@page - 1) }, title: 'Ga een pagina verder')
              end
    output << "</li>"

    1.upto(@pages) do |i|
      output << "<li>"
      output << if @page == i
                  i.to_s
                else
                  link_to(i, { action: 'page', page_number: i }, title: "Ga naar pagina #{i}")
                end
      output << "</li>"
    end

    output << "<li>"
    output << if @page == @pages
                "ouder »"
              else
                link_to("ouder »", { action: 'page', page_number: (@page + 1) }, title: 'Ga een pagina terug')
              end
    output << "</li>"

    output << "</ul>"
    output.html_safe
  end
end
