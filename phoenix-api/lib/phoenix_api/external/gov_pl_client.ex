defmodule PhoenixApi.External.GovPlClient do
  @moduledoc """
  Client for fetching Polish names data from dane.gov.pl (Polish Open Data Portal).
  """

  require Logger

  # Dataset resource IDs from dane.gov.pl
  # Dataset 1667: Lista imion występujących w rejestrze PESEL osoby żyjące
  @first_names_resource_id "20591"
  # Dataset 1681: Nazwiska osób żyjących występujące w rejestrze PESEL
  @surnames_resource_id "42925"

  @doc """
  Fetches Polish first names from gov.pl and returns them categorized by gender.
  Returns {:ok, %{male: [...], female: [...]}} or {:error, reason}
  """
  def fetch_first_names do
    url = "https://api.dane.gov.pl/media/resources/#{@first_names_resource_id}/Lista_imion_wystepujacych_w_rejestrze_PESEL_-_28_stycznia_2025.csv"
    
    case fetch_csv_data(url) do
      {:ok, csv_data} -> parse_first_names_csv(csv_data)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches Polish surnames from gov.pl and returns them categorized by gender.
  Returns {:ok, %{male: [...], female: [...]}} or {:error, reason}
  """
  def fetch_surnames do
    url = "https://api.dane.gov.pl/media/resources/#{@surnames_resource_id}/Nazwiska_występujące_w_rejestrze_PESEL_-_29_stycznia_2024.csv"
    
    case fetch_csv_data(url) do
      {:ok, csv_data} -> parse_surnames_csv(csv_data)
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp fetch_csv_data(url) do
    Logger.info("Fetching data from gov.pl: #{url}")
    
    case Req.get(url, decode_body: false) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}
      
      {:ok, %Req.Response{status: status}} ->
        Logger.error("Failed to fetch from gov.pl: HTTP #{status}")
        {:error, "HTTP #{status}"}
      
      {:error, reason} ->
        Logger.error("Failed to fetch from gov.pl: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_first_names_csv(csv_data) do
    try do
      # Parse CSV - expecting format: Imie,Liczba,Plec (Name,Count,Gender)
      rows = 
        csv_data
        |> NimbleCSV.RFC4180.parse_string(skip_headers: true)
      
      male_names = 
        rows
        |> Enum.filter(fn [_name, _count, gender] -> String.downcase(gender) == "m" end)
        |> Enum.map(fn [name, _count, _gender] -> name end)
        |> Enum.uniq()
        |> Enum.take(100)  # Limit to top 100 names
      
      female_names = 
        rows
        |> Enum.filter(fn [_name, _count, gender] -> String.downcase(gender) == "k" end)
        |> Enum.map(fn [name, _count, _gender] -> name end)
        |> Enum.uniq()
        |> Enum.take(200)  # Limit to top 200 names
      
      {:ok, %{male: male_names, female: female_names}}
    rescue
      e ->
        Logger.error("Failed to parse first names CSV: #{inspect(e)}")
        {:error, "Failed to parse CSV"}
    end
  end

  defp parse_surnames_csv(csv_data) do
    try do
      # Parse CSV - expecting format: Nazwisko,Liczba (Surname,Count)
      all_surnames = 
        csv_data
        |> NimbleCSV.RFC4180.parse_string(skip_headers: true)
        |> Enum.map(fn [surname | _] -> surname end)
        |> Enum.uniq()
      
      # Separate into male and female forms
      # Female surnames typically end in: -ska, -cka, -dzka, -a (after consonant)
      # Male surnames typically end in: -ski, -cki, -dzki, or consonant
      
      {female_surnames, male_surnames} = 
        all_surnames
        |> Enum.split_with(fn surname ->
          String.ends_with?(surname, ["ska", "cka", "dzka"]) or
          (String.ends_with?(surname, "a") and not String.ends_with?(surname, ["ia", "ya"]))
        end)
      
      # Take top 100 of each
      male_surnames = Enum.take(male_surnames, 100)
      female_surnames = Enum.take(female_surnames, 100)
      
      {:ok, %{male: male_surnames, female: female_surnames}}
    rescue
      e ->
        Logger.error("Failed to parse surnames CSV: #{inspect(e)}")
        {:error, "Failed to parse CSV"}
    end
  end
end
