defmodule CrawlyUIWeb.LayoutView do
  use CrawlyUIWeb, :view

  def ga_js_tag() do
    case System.get_env("GA_TRACKING") do
      nil ->
        ""

      tracking_code ->
        """
        <!-- Google Tag Manager -->
        <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
        new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
        j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
        'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
        })(window,document,'script','dataLayer','#{tracking_code}');</script>
        <!-- End Google Tag Manager -->
        """
    end
  end

  def ga_nojs_tag() do
    case System.get_env("GA_TRACKING") do
      nil ->
        ""

      tracking_code ->
        """
        <!-- Google Tag Manager (noscript) -->
        <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=#{tracking_code}"
        height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
        <!-- End Google Tag Manager (noscript) -->
        """
    end
  end
end
