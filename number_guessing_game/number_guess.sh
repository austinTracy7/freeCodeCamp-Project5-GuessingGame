#!/bin/bash

# # getting the user information
echo "Enter your username:"

read USERNAME

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

USER_ID=$($PSQL "SELECT user_id FROM Users WHERE username='$USERNAME';")

if [ -z $USER_ID ]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_RESPONSE=$($PSQL "INSERT INTO users (username) VALUES('$USERNAME');")
  USER_ID=$($PSQL "SELECT user_id FROM Users WHERE username='$USERNAME'")
  INSERT_RESPONSE=$($PSQL "INSERT INTO best_scores (user_id,games_played) VALUES($USER_ID,0);")
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM best_scores WHERE user_id=$USER_ID;")
  BEST_SCORE=$($PSQL "SELECT best_score FROM best_scores WHERE user_id=$USER_ID;")
  if [ -z $BEST_SCORE ]
  then
    echo "Welcome back, $USERNAME! You haven't played any games yet. You should give it a go."
  else
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_SCORE guesses."
  fi
fi

# creating a function for testing for the best game and saving game stats
CHECK_IF_BEST_GAME(){
  BEST_SCORE=$($PSQL "SELECT best_score FROM best_scores WHERE user_id=$USER_ID;")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM best_scores WHERE user_id=$USER_ID;")
  GAMES_PLAYED=$(($GAMES_PLAYED+1))
  if [ -z $BEST_SCORE ]
  then
    NEW_BEST=True
  else
    if [ $1 -lt $BEST_SCORE ]
    then
    NEW_BEST=True
    fi
  fi
  if [ $NEW_BEST ]
  then
    UPDATE_RESPONSE=$($PSQL "UPDATE best_scores SET best_score = $1, games_played = $GAMES_PLAYED WHERE user_id=$USER_ID;")
  else
    UPDATE_RESPONSE=$($PSQL "UPDATE best_scores SET games_played = $GAMES_PLAYED WHERE user_id=$USER_ID;")
  fi
}

# running the number guessing game
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))

GUESS_THE_NUMBER(){
  GUESS_NUMBER=$(($2+1))
  echo $1
  read GUESS
  if [[ $GUESS =~ ^[0-9]+$ ]]
  then
    if [ $GUESS -lt $RANDOM_NUMBER ]
    then
      GUESS_THE_NUMBER "It's higher than that, guess again:" GUESS_NUMBER
    elif [ $GUESS -gt $RANDOM_NUMBER ]
    then
      GUESS_THE_NUMBER "It's lower than that, guess again:" GUESS_NUMBER
    else
      echo "You guessed it in ${GUESS_NUMBER} tries. The secret number was ${RANDOM_NUMBER}. Nice job!'"
      CHECK_IF_BEST_GAME $GUESS_NUMBER
    fi
  else
    GUESS_THE_NUMBER "That is not an integer, guess again:"
  fi
}

GUESS_THE_NUMBER "Guess the secret number between 1 and 1000:" 0
