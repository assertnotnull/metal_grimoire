defmodule MetalGrimoire.Scraper.BandScraper do
  @base_url "https://www.metal-archives.com"
  # https://www.metal-archives.com/search/ajax-band-search/?field=name&query=priest&sEcho=1&iColumns=3&sColumns=&iDisplayStart=0&iDisplayLength=200&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2
  def run(band) do
    document = perform_request_and_parse_result(band)

    find_and_parse_rows(document)
    # |> IO.inspect()

    # |> save_rows()

    # maybe_paginate(document)
  end

  defp perform_request_and_parse_result(band) do
    # params =
    #   %{field: "name", query: "priest"}
    #   |> URI.encode_query()

    path =
      "#{@base_url}/search/ajax-band-search?field=name&query=#{band}&sEcho=1&iColumns=3&sColumns=&iDisplayStart=0&iDisplayLength=200&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2"

    # IO.inspect(path)

    {:ok, %Finch.Response{body: body}} =
      Finch.build(:get, path)
      |> Finch.request(BandScraperProcess)

    # IO.inspect(body)

    {:ok, document} = Floki.parse_document(body)
    # IO.inspect(document)

    document
  end

  defp find_and_parse_rows(document) do
    IO.inspect(Floki.find(document, "tr td"))

    results =
      document
      |> Floki.find(" ")

    [_header | entries] = document
    IO.inspect(entries)

    # Enum.chunk_by(bands, fn rec -> is_tuple(rec) && elem(rec, 0) == "a" end)

    chunk_fun = fn el, acc ->
      if length(acc) > 0 && is_tuple(el) && elem(el, 0) == "a" do
        {:cont, Enum.reverse(acc), [el]}
      else
        {:cont, [el | acc]}
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    bands =
      Enum.chunk_while(entries, [], chunk_fun, after_fun)
      |> Enum.map(fn row_list ->
        case row_list do
          [{"a", [_link], [name]}, _comment, desc] -> {name, desc}
          [{"a", [_link], [name]}, " (", _aka, _aliases, _comment, desc] -> {name, desc}
        end
      end)
      |> Enum.map(fn {band, desc} ->
        %{"country" => country, "kind" => kind} =
          Regex.replace(~r/\t|\r|\n|,/, desc, "")
          |> then(fn cleaned ->
            Regex.named_captures(~r/\" \"(?<kind>.+)\" \"(?<country>.+)\" .*/iu, cleaned)
          end)

        %{band: band, country: country, kind: kind}
      end)

    IO.inspect(bands)

    # |> Enum.map(fn [a_link, _comment, details] )

    # results
    # |> Enum.each(fn entry ->
    #   entry
    #   |> Floki.raw_html()
    #   |> IO.inspect()
    # end)

    list =
      results
      |> Enum.map(fn result ->
        %{
          name: Floki.text(result),
          url: Floki.attribute(result, "href") |> hd() |> String.replace(~r/\\\"/, "")
        }
      end)

    # IO.inspect(list)

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
