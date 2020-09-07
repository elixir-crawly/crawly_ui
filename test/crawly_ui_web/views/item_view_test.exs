defmodule CrawlyUIWeb.ItemViewTest do
  import CrawlyUI.DataCase
  use CrawlyUIWeb.ConnCase

  import Phoenix.View
  import Ecto.Query

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

      query = from i in CrawlyUI.Manager.Item, where: i.job_id == ^job_id
      items = CrawlyUI.Repo.all(query)
      page = CrawlyUI.Repo.paginate(query, %{})

      params = [items: items, page: page, search: nil]

      rendered_string = render_to_string(CrawlyUIWeb.ItemView, "index.html", params)

      assert rendered_string =~
               "<td class=\"w\"><b>field_1</b></td>\n   <td class=\"c\">data_1</td>"

      # test render image
      assert rendered_string =~ "<td class=\"c\"><img width='150px' src='image_1_src' /></td>"

      # test render url
      assert rendered_string =~
               "<td class=\"c\"><a target='blank' href='http://example_1.com'>http://example_1.com</a></td>"

      assert rendered_string =~
               "<th>Discovery time: #{item_1.inserted_at} [<a href='/jobs/#{job_id}/items/#{
                 item_1.id
               }'> Preview </a>]</th>"

      assert rendered_string =~
               "<td class=\"w\"><b>field_1</b></td>\n   <td class=\"c\">data_2</td>"

      assert rendered_string =~
               "<td class=\"c\"><a target='blank' href='https://example_2.com'>https://example_2.com</a></td>"

      assert rendered_string =~
               "<th>Discovery time: #{item_2.inserted_at} [<a href='/jobs/#{job_id}/items/#{
                 item_2.id
               }'> Preview </a>]</th>"

      # test render list
      assert rendered_string =~ "<td class=\"c\">data_2data_1</td>"
    end

    test "with empty search string" do
      params = index_params(%{"field" => "value"}, nil)

      assert render_to_string(CrawlyUIWeb.ItemView, "index.html", params) =~
               "<div class=\"column\"><input type=\"text\" placeholder=\"Search\" name=\"search\"></div>"
    end

    test "with search param" do
      params = index_params(%{"field" => "value"}, "search string")

      assert render_to_string(CrawlyUIWeb.ItemView, "index.html", params) =~
               "<div class=\"column\"><input type=\"text\" placeholder=\"search string\" name=\"search\"></div>"
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

      params = [item: item, next_item: next_item]

      rendered_string = render_to_string(CrawlyUIWeb.ItemView, "show.html", params)

      assert rendered_string =~
               "<a href='/jobs/#{next_item.job_id}/items/#{next_item.id}'> Next Item </a>"

      assert rendered_string =~ "<a href=\"/jobs/#{item.job_id}/items/\"> Go to items </a>"

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

    query =
      from i in CrawlyUI.Manager.Item,
        where: i.job_id == ^job_id

    items = CrawlyUI.Repo.all(query)

    page = CrawlyUI.Repo.paginate(query, %{})
    [items: items, page: page, search: search]
  end
end
