defmodule CrawlyUIWeb.ItemViewTest do
  import CrawlyUI.DataCase
  use CrawlyUIWeb.ConnCase

  import Phoenix.View

  describe "render jobs/:job_id/items/index.html" do
    test "shows list items" do
      %{id: job_id} = insert_job()

      item_1 =
        insert_item(job_id, nil, %{
          "field_1" => "data_1",
          "url" => "http://example_1.com",
          "image" => "image_1_src"
        })

      item_2 =
        insert_item(job_id, nil, %{
          "field_1" => "data_2",
          "url" => "https://example_2.com",
          "list" => ["data_1", "data_2"]
        })

      %{total_pages: total_page, entries: rows} = CrawlyUI.Manager.list_items(job_id)

      params = [job_id: job_id, total_pages: total_page, search: nil, rows: rows, page: 1]

      rendered_string = render_to_string(CrawlyUIWeb.ItemView, "index.html", params)

      assert rendered_string =~
               "<td class=\"w\"><b>field_1</b></td>\n      <td class=\"c\">data_1</td>"

      # test render image
      assert rendered_string =~ "<td class=\"c\"><img width='150px' src='image_1_src' /></td>"

      # test render url
      assert rendered_string =~
               "<td class=\"c\"><a target='blank' href='http://example_1.com'>http://example_1.com</a></td>"

      assert rendered_string =~
               "<th>Discovery time: #{item_1.inserted_at}\n <a href=\"#\" phx-click=\"show_item\" phx-value-job=#{
                 job_id
               } phx-value-item=#{item_1.id}> Preview </a>"

      assert rendered_string =~
               "<td class=\"w\"><b>field_1</b></td>\n      <td class=\"c\">data_2</td>"

      assert rendered_string =~
               "<td class=\"c\"><a target='blank' href='https://example_2.com'>https://example_2.com</a></td>"

      assert rendered_string =~
               "<th>Discovery time: #{item_2.inserted_at}\n <a href=\"#\" phx-click=\"show_item\" phx-value-job=#{
                 job_id
               } phx-value-item=#{item_2.id}> Preview </a>"

      # test render list
      assert rendered_string =~ "<td class=\"c\">data_2data_1</td>"
    end

    test "with empty search string" do
      params = index_params(%{"field" => "value"}, nil)

      assert render_to_string(CrawlyUIWeb.ItemView, "index.html", params) =~
               "<input type=\"text\" placeholder=\"Search\" name=\"search\" autocomplete=\"off\">"
    end

    test "with search param" do
      params = index_params(%{"field" => "value"}, "search string")

      assert render_to_string(CrawlyUIWeb.ItemView, "index.html", params) =~
               "<input type=\"text\" value=\"search string\" name=\"search\" autocomplete=\"off\">"
    end
  end

  describe "render jobs/:job_id/items/:id/show.html" do
    test "show item data" do
      %{id: job_id} = insert_job()

      item =
        insert_item(job_id, nil, %{
          "field_1" => "data_1",
          "url" => "http://example_1.com",
          "image" => "image_1_src"
        })

      next_item =
        insert_item(job_id, nil, %{
          "field_1" => "data_2",
          "url" => "https://example_2.com",
          "image" => "image_2_src"
        })

      params = [job_id: job_id, item: item, next_item: next_item]

      rendered_string = render_to_string(CrawlyUIWeb.ItemView, "show.html", params)

      assert rendered_string =~
               "<a href=\"#\" phx-click=\"show_item\" phx-value-job=#{job_id} phx-value-item=#{
                 next_item.id
               }> Next Item </a>"

      assert rendered_string =~
               "<a href=\"#\" phx-click=\"job_items\" phx-value-job=#{job_id}> Go to items </a>"

      assert rendered_string =~
               "<b>field_1</b>:\n            <br />\ndata_1"

      # test render image
      assert rendered_string =~ "<br />\n<img width='150px' src='image_1_src' />"

      # test render url
      assert rendered_string =~
               "<br />\n<a target='blank' href='http://example_1.com'>http://example_1.com</a>"
    end
  end

  defp index_params(data, search) do
    %{id: job_id} = insert_job()
    insert_item(job_id, nil, data)

    %{total_pages: total_pages, entries: rows} = CrawlyUI.Manager.list_items(job_id)
    [job_id: job_id, total_pages: total_pages, search: search, rows: rows, page: 1]
  end
end
