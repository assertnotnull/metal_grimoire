defmodule MetalGrimoire.Scraper.BandScraper do
  @base_url "https://www.metal-archives.com"
  # https://www.metal-archives.com/search/ajax-band-search/?field=name&query=priest&sEcho=1&iColumns=3&sColumns=&iDisplayStart=0&iDisplayLength=200&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2
  def run() do
    document = perform_request_and_parse_result()

    find_and_parse_rows(document)
    # |> IO.inspect()

    # |> save_rows()

    # maybe_paginate(document)
  end

  defp perform_request_and_parse_result() do
    # params =
    #   %{field: "name", query: "priest"}
    #   |> URI.encode_query()

    path =
      "#{@base_url}/search/ajax-band-search?field=name&query=priest&sEcho=1&iColumns=3&sColumns=&iDisplayStart=0&iDisplayLength=200&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2"

    IO.inspect(path)

    {:ok, %Finch.Response{body: body}} =
      Finch.build(:get, path)
      |> Finch.request(BandScraperProcess)

    IO.inspect(body)

    {:ok, document} = Floki.parse_document(body)
    IO.inspect(document)

    document
  end

  defp find_and_parse_rows(document) do
    results =
      document
      |> Floki.find("a")
      |> IO.inspect()

    list =
      results
      |> Enum.map(fn result ->
        %{
          name: Floki.text(result),
          url: Floki.attribute(result, "href") |> hd() |> String.replace(~r/\\\"/, "")
        }
      end)

    IO.inspect(list)

    # |> Enum.map(&parse_row/1)
  end

  defp parse_row(
         {"tr", _,
          [
            {"td", _, [{"a", _, [city_state_country]}]},
            {"td", _, [latitude]},
            {"td", _, [longitude]}
          ]}
       ) do
    [city, state | _] =
      city_state_country
      |> String.split(",", trim: true)

    %{city: city, state: state, latitude: latitude, longitude: longitude}
  end

  defp parse_row(_), do: %{}

  # defp save_rows(rows) do
  #   rows
  #   |> Enum.each(&Scraping.Cities.create_city/1)
  # end

  # defp maybe_paginate(document) do
  #   document
  #   |> Floki.find(".pagination li a")
  #   |> Enum.find(fn row ->
  #     case row do
  #       {"a", [{"href", "/" <> _path}], ["next" <> _]} -> true
  #       _ -> false
  #     end
  #   end)
  #   |> case do
  #     nil ->
  #       :ok

  #     {_, [{_, "" <> path}], _} ->
  #       run(path)
  #   end
  # end
end
