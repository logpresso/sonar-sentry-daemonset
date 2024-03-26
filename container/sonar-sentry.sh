#!/bin/bash

# Determine the action based on the first argument
action=$1

# Determine the sentry name based on the second argument, default to 'sonar-sentry-001' if not provided
sentry_name=${2:-sonar-sentry-001}

case $action in
	build)
		# Build the 'sonar-sentry' Docker image
		docker build -t sonar-sentry .
		echo "The 'sonar-sentry' Docker image has been built."
		;;
	rebuild)
		# Execute the build action
		$0 build

		# Stop the container
		$0 stop $sentry_name

		# Remove the container
		docker rm $sentry_name
		echo "The container $sentry_name has been removed."

		# Start the container
		$0 start $sentry_name
		;;
	start)
		# Execute the Logpresso Sentry start command in the '$sentry_name' container
		if [ $(docker ps -q -f name=$sentry_name) ]; then
			echo "The container $sentry_name is already running."
		else
			docker run -d --name $sentry_name sonar-sentry
			echo "Logpresso Sentry has been started in the container $sentry_name."
		fi
		;;
	stop)
		# Execute the Logpresso Sentry stop command in the '$sentry_name' container
		if [ $(docker ps -q -f name=$sentry_name) ]; then
			docker exec $sentry_name /opt/logpresso-sentry/logpresso stop
			echo "Logpresso Sentry has been stopped in the container $sentry_name."
		else
			echo "There is no running container named $sentry_name."
		fi
		;;
	tail)
		# Tail the log file in real-time from the '$sentry_name' container
		if [ $(docker ps -q -f name=$sentry_name) ]; then
			docker exec -it $sentry_name tail -F /opt/logpresso-sentry/log/araqne.log
		else
			echo "There is no running container named $sentry_name."
		fi
		;;
	status)
		# Check the status of the '$sentry_name' container
		if [ $(docker ps -q -f name=$sentry_name) ]; then
			echo "The container $sentry_name is currently running."
		elif [ $(docker ps -aq -f name=$sentry_name) ]; then
			echo "The container $sentry_name exists but is not running."
		else
			echo "There is no container named $sentry_name."
		fi
		;;
	terminate)
		# Stop the container
		if [ $(docker ps -q -f name=$sentry_name) ]; then
			docker stop $sentry_name
			echo "The container $sentry_name has been stopped."
		else
			echo "There is no running container named $sentry_name."
		fi

		# Remove the container
		docker rm $sentry_name
		echo "The container $sentry_name has been removed."
		;;
	*)
		echo "Available commands: build, rebuild, start, stop, tail, status, terminate"
		;;
esac