defmodule PhoenixApi.Accounts.DataImport do
  @moduledoc """
  Module for importing user data from gov.pl open data services.
  Fetches fresh data on each import.
  """

  require Logger
  alias PhoenixApi.External.GovPlClient

  # Fallback minimal lists in case gov.pl is unavailable
  @fallback_male_names ~w(Jan Piotr Krzysztof Andrzej Tomasz)
  @fallback_female_names ~w(Maria Anna Katarzyna Małgorzata Barbara)
  @fallback_male_surnames ~w(Nowak Kowalski Wiśniewski Wójcik Kowalczyk)
  @fallback_female_surnames ~w(Nowak Kowalska Wiśniewska Wójcik Kowalczyk)

  @doc """
  Generates 100 random users by fetching fresh data from gov.pl.
  Returns user data ready to be inserted into the database.
  """
  def generate_users(count \\ 100) do
    Logger.info("Fetching fresh data from gov.pl for user generation...")
    
    # Fetch names from gov.pl
    {male_names, female_names, male_surnames, female_surnames} = fetch_names_from_govpl()
    
    # Generate users
    for _ <- 1..count do
      gender = Enum.random([:male, :female])
      
      {first_name, last_name} = case gender do
        :male -> 
          {Enum.random(male_names), Enum.random(male_surnames)}
        :female -> 
          {Enum.random(female_names), Enum.random(female_surnames)}
      end
      
      %{
        first_name: first_name,
        last_name: last_name,
        gender: gender,
        birthdate: random_birthdate()
      }
    end
  end

  defp fetch_names_from_govpl do
    # Fetch first names
    {male_names, female_names} = case GovPlClient.fetch_first_names() do
      {:ok, %{male: males, female: females}} ->
        Logger.info("Loaded #{length(males)} male and #{length(females)} female names from gov.pl")
        {males, females}
      
      {:error, reason} ->
        Logger.warning("Failed to fetch first names from gov.pl: #{inspect(reason)}, using fallback")
        {@fallback_male_names, @fallback_female_names}
    end
    
    # Fetch surnames
    {male_surnames, female_surnames} = case GovPlClient.fetch_surnames() do
      {:ok, %{male: males, female: females}} ->
        Logger.info("Loaded #{length(males)} male and #{length(females)} female surnames from gov.pl")
        {males, females}
      
      {:error, reason} ->
        Logger.warning("Failed to fetch surnames from gov.pl: #{inspect(reason)}, using fallback")
        {@fallback_male_surnames, @fallback_female_surnames}
    end
    
    {male_names, female_names, male_surnames, female_surnames}
  end

  defp random_birthdate do
    start_date = ~D[1970-01-01]
    end_date = ~D[2024-12-31]
    days_diff = Date.diff(end_date, start_date)
    Date.add(start_date, :rand.uniform(days_diff + 1) - 1)
  end
end


