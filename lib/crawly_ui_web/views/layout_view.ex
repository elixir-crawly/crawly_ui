defmodule CrawlyUIWeb.LayoutView do
  use CrawlyUIWeb, :view

  def ga_tag() do
    case System.get_env("GA_TRACKING") do
      nil ->
        ""

      tracking_code ->
        """
        <!-- Global site tag (gtag.js) - Google Analytics -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=#{tracking_code}"></script>
        <script>
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());

          gtag('config', '#{tracking_code}');
        </script>
        """
    end
  end
end
