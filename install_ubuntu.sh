#!/bin/sh

echo
echo "+------------------------------+"
echo "|     FicTrac install script   |"
echo "+------------------------------+"
echo

# Get Ubuntu version
ver="$(lsb_release -sr)"
echo "Found Ubuntu version $ver"

if [ "$ver" = "22.04" ] || [ "$ver" = "20.04" ]; then
	echo
	echo "+-- Installing dependencies ---+"
	echo
	sudo apt-get update
	sudo apt-get install -y gcc g++ cmake libavcodec-dev libnlopt-dev libboost-dev libopencv-dev
	
	echo
	echo "+-- Creating build directory --+"
	echo
	FICTRAC_DIR="$(dirname "$0")"
	cd "$FICTRAC_DIR"	# make sure we are in fictrac dir
	if [ -d ./build ]; then
		echo "Removing existing build dir"
		rm -r ./build
	fi
	mkdir build
	if [ -d ./build ]; then
		echo "Created build dir"
		cd ./build
	else
		echo "Uh oh, something went wrong attempting to create the build dir!"
		exit
	fi
	
	# --- Optional: Configure Camera SDK Support ---
	echo
	echo "+-- Optional: Camera SDK Support --+"
	echo "Please choose a camera SDK to build with(For now only Spinnaker build is supported):"
	echo "  1) Spinnaker (PGR_USB3)"
	echo "  2) FlyCapture (PGR_USB2)"
	echo "  3) Basler Pylon (BASLER_USB3)"
	echo "  4) None (default)"
	echo -n "Enter your choice [1-4]: "
	read -r sdk_choice

	# Set the default cmake command
	cmake_command="cmake .."
	sdk_path=""
	
	case $sdk_choice in
		1)
			# Check for default Spinnaker path
			default_spinnaker_path="/opt/spinnaker"
			use_default=n

			if [ -d "$default_spinnaker_path" ]; then
				echo -n "Found Spinnaker SDK at default location ($default_spinnaker_path). Use this? (Y/n): "
				read -r use_default_input
				# If user presses enter or types 'y'/'Y', use the default
				if [ -z "$use_default_input" ] || [ "$use_default_input" = "y" ] || [ "$use_default_input" = "Y" ]; then
					sdk_path="$default_spinnaker_path"
					use_default=y
				fi
			fi

			# If default was not used, prompt for path
			if [ "$use_default" = "n" ]; then
				echo -n "Please enter the full path to your Spinnaker SDK directory: "
				read -r sdk_path
			fi

			# Validate the final path and set the command
			if [ -n "$sdk_path" ] && [ -d "$sdk_path" ]; then
				echo "-> Will build with Spinnaker (PGR_USB3) support using SDK at: $sdk_path"
				cmake_command="cmake -D PGR_USB3=ON -D PGR_DIR=\"$sdk_path\" .."
			else
				echo "-> WARNING: Invalid path provided. Building WITHOUT camera SDK support."
			fi
			;;
		2)
			echo -n "Please enter the full path to your FlyCapture SDK directory: "
			read -r sdk_path
			if [ -n "$sdk_path" ] && [ -d "$sdk_path" ]; then
				echo "-> Will build with FlyCapture (PGR_USB2) support."
				cmake_command="cmake -D PGR_USB2=ON -D PGR_DIR=\"$sdk_path\" .."
			else
				echo "-> WARNING: Invalid path provided. Building WITHOUT camera SDK support."
			fi
			;;
		3)
			echo -n "Please enter the full path to your Basler Pylon SDK directory: "
			read -r sdk_path
			if [ -n "$sdk_path" ] && [ -d "$sdk_path" ]; then
				echo "-> Will build with Basler Pylon (BASLER_USB3) support."
				cmake_command="cmake -D BASLER_USB3=ON -D BASLER_DIR=\"$sdk_path\" .."
			else
				echo "-> WARNING: Invalid path provided. Building WITHOUT camera SDK support."
			fi
			;;
		*)
			echo "-> Building without special camera SDK support."
			;;
	esac
	
	echo
	echo "+-- Generating build files ----+"
	echo "Running command: $cmake_command"
	echo
	# Execute the constructed cmake command
	eval $cmake_command
	
	echo
	echo "+-- Building FicTrac ----------+"
	echo
	cmake --build . --config Release --parallel $(nproc) --clean-first
	
	cd ..
	if [ -f ./bin/fictrac ]; then
		echo
		echo "FicTrac built successfully!"
		echo
	else
		echo
		echo "Hmm... something seems to have gone wrong - can't find FicTrac executable."
		echo
	fi
fi

