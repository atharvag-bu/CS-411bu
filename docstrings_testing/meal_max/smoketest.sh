#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5000/api"

# Flag to control whether to echo JSON output
ECHO_JSON=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    --echo-json) ECHO_JSON=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done


###############################################
#
# Health checks
#
###############################################

# Function to check the health of the service
check_health() {
  echo "Checking health status..."
  curl -s -X GET "$BASE_URL/health" | grep -q '"status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  curl -s -X GET "$BASE_URL/db-check" | grep -q '"database_status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}


##########################################################
#
# Meal Management
#
##########################################################

create_meal() {
  meal = $1
  cuisine = $2
  price = $3
  difficulty = $4

  echo "Attempting to add new meal ($meal, $cuisine, $price, $difficulty) to the battle..."
  response=$(curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}")
  
  if echo "$response" | grep -q '"status": "success"'; then 
    echo "Meal succesfully added"
  else 
    echo "Failed to add meal"
    exit 1
  fi
}

remove_meal() {
  meal = $1

  echo "Removing meal by ID ($meal)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal")
  if echo "$response" | grep -q '"status": *"success"'; then
    echo "Meal removed successfully by ID ($meal)."
  else
    echo $response
    echo "Failed in removing meal with ID ($meal)."
    exit 1
  fi
}

clear_meal_catalog() {
  echo "Attempting to clear the kitchen catalog..."
  curl -s -X DELETE "$BASE_URL/clear-meals" | grep -q '"status": "success"'
}

retrieve_meal_by_name() {
  meal_name = $1

  echo "Getting meal by name ($meal_name)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name/$(echo $meal_name | sed 's/ /%20/g')")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by name ($meal_name)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (Name $meal_name):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve meal by name ($meal_name)."
    exit 1
  fi
}

get_meal_by_id() {
  meal_id = $1

  echo "Retrieving meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": *"success"'; then
    echo "Meal successfully retrieved by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by ID ($meal_id)."
    exit 1
  fi
}

prepare_combatant() {
  meal = $1

  echo "Preparing for battle: $meal ..."
  response=$(curl -s -X POST "$BASE_URL/prep-combatant" \
    -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\"}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatant prepared succesfully"
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON:"
      echo "$response" | jq .
    fi
  else
    echo $response
    echo "Failed to prepare combatant"
    exit 1
  fi
}

list_combatants() {  
  echo "Retrieving all battle combatants..."
  response=$(curl -s -X GET "$BASE_URL/get-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants retrieved successfully.."
    if [ "$ECHO_JSON" = true ]; then
      echo "Combatants JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to retrieve combatants."
    exit 1
  fi
}

initiate_battle() {
  echo "Entering battle..."
  response=$(curl -s -X GET "$BASE_URL/battle")

  if echo "$response" | grep -q '"status": *"success"'; then
    echo "Battle successfull."
  else
    echo $response
    echo "Failed to start battle."
    exit 1
  fi
}

get_leaderboard() {
  sort=$1
  echo "Retrieving meal leaderboard sorted by $sort..."
  response=$(curl -s -X GET "$BASE_URL/leaderboard?sort=$sort")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON (sorted by $sort):"
      echo "$response" | jq .
    fi
  else
    echo $response 
    echo "Failed to get meal leaderboard."
    exit 1
  fi
}

clear_all_combatants() {
  echo "Attempting to clear all combatants..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "All combatants cleared."
  else
    echo "Failed to clear combatants."
    exit 1
  fi
}


# Health checks
check_health
check_db

# Create meals
create_meal "Spaghetti" "Italian" 10 "LOW"
create_meal "Tacos" "Mexican" 6 "HIGH"
create_meal "Sushi" "Japanese" 12 "MED"
create_meal "Burger" "American" 15 "LOW"
create_meal "Curry" "Indian" 9 "HIGH"
create_meal "Churros" "Spanish" 8 "MED"
create_meal "Crepes" "French" 7 "LOW"

#testing retrieve and delete
retrieve_meal_by_id 2
retrieve_meal_by_name "Tacos"
remove_meal 6

#resetting delete
create_meal "Churros" "Spanish" 8 "MED"

#starting battles

# battle 1
clear_all_combatants
prepare_combatant "Spaghetti"
prepare_combatant "Burger"
initiate_battle

# battle 2
clear_all_combatants
prepare_combatant "Sushi"
prepare_combatant "Churros"
initiate_battle

# leaderboard
retrieve_leaderboard

#all tests completed

echo "All tests completed successfully!"