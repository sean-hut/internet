;;; internet.el --- Connect to the internet through a variety of methods -*- lexical-binding: t -*-

;; Copyright © 2020 Sean Hutchings <seanhut@yandex.com>

;; Author: Sean Hutchings <seanhut@yandex.com>
;; Maintainer: Sean Hutchings <seanhut@yandex.com>
;; Created: 2020-11-18
;; Keywords: comm, processes, terminals, unix
;; Version: 0.1.0-git
;; Package-Requires: ((emacs "25.1"))
;; Homepage: https://github.com/sean-hut/internet
;; License: BSD Zero Clause License (SPDX:0BSD)

;; Permission to use, copy, modify, and/or distribute this software
;; for any purpose with or without fee is hereby granted.
;;
;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
;; WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
;; AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
;; CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
;; OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
;; NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
;; CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

;;; Change Log: For all notable changes see CHANGELOG.md

;;; Commentary:

;; Connect to the internet through a variety of methods.
;;
;; Functionality:
;;
;; - Methods of connecting to the internet
;;     - Ethernet
;;     - Wireless
;;     - Ethernet and openvpn
;;     - Wireless and openvpn
;;
;; - Disconnect for the above connecting options
;;
;; - Add and remove wireless network configurations
;;
;; Repository: https://github.com/sean-hut/internet
;;
;; Documentation: https://sean-hut.github.io/internet/

;;; Code:

(require 'seq)
(require 'subr-x)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ethernet connection configuration variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar internet-ethernet-interface "enp3s0"
  "Ethernet interface.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wireless connection configuration variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar internet-wpa-supplicant-config-directory "/etc/wpa_supplicant/"
  "Directory where wpa_supplicant configuration files are located.")

(defvar internet-rfkill-device-id "0"
  "Device ID for rfkill.")

(defvar internet-wireless-interface "wlp4s0"
  "Wireless interface.")

(defvar internet-wpa-supplicant-driver "nl80211"
  "Driver to be used with wpa_supplicant.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; openvpn connection configuration variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar internet-openvpn-config-directory "/home/user-name/openvpn/configurations/"
  "The directory where openvpn configuration files are located.")

;;;;;;;;;;;;;;;;;;;;;
;; rfkill commands ;;
;;;;;;;;;;;;;;;;;;;;;

(defun internet--rfkill-unblock-command ()
  "Command to soft unblock wireless device using rfkill."
  (concat "sudo --stdin rfkill unblock "
	  (shell-quote-argument internet-rfkill-device-id)))

(defun internet--rfkill-block-command ()
  "Command to soft block wireless device using rfkill."
  (concat "sudo --stdin rfkill block "
	  (shell-quote-argument internet-rfkill-device-id)))

;;;;;;;;;;;;;;;;;;;;;;
;; ip link commands ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun internet--ip-link-wireless-up-command ()
  "Command to set wireless interface to up using ip link."
  (concat "sudo --stdin ip link set "
	  (shell-quote-argument internet-wireless-interface)
	  " up"))

(defun internet--ip-link-wireless-down-command ()
  "Command to set wireless interface to down using ip link."
  (concat "sudo --stdin ip link set "
	  (shell-quote-argument internet-wireless-interface)
	  " down"))

(defun internet--ip-link-ethernet-up-command ()
  "Command to set wireless interface to up using ip link."
  (concat "sudo --stdin ip link set "
	  (shell-quote-argument internet-ethernet-interface)
	  " up"))

(defun internet--ip-link-ethernet-down-command ()
  "Command to set wireless interface to down using ip link."
  (concat "sudo --stdin ip link set "
	  (shell-quote-argument internet-ethernet-interface)
	  " down"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wpa_supplicant commands ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet--wpa-supplicant-connect-command (network-name)
  "Return wpa_supplicant connection command.

The command is used to connect to a wireless network.

NETWORK-NAME is the network to connect to."

  (concat "sudo --stdin wpa_supplicant -B"
	  " -D"
	  (shell-quote-argument internet-wpa-supplicant-driver)
	  " -c"
	  (concat
	   (shell-quote-argument internet-wpa-supplicant-config-directory)
	   (shell-quote-argument network-name)
	   ".conf")
	  " -i"
	  (shell-quote-argument internet-wireless-interface)))

(defconst internet--kill-wpa-supplicant-command
  '"sudo --stdin pkill wpa_supplicant"
  "Command to kill wpa_supplicant process.")

;;;;;;;;;;;;;;;;;;;;;;;
;; dhclient commands ;;
;;;;;;;;;;;;;;;;;;;;;;;

(defun internet--dhclient-get-wireless-ip-address-command ()
  "Command to get ip address using dhclient."
  (concat "sudo --stdin dhclient "
	  (shell-quote-argument internet-wireless-interface)))

(defun internet--dhclient-get-ethernet-ip-address-command ()
  "Command to get ip address using dhclient."
  (concat "sudo --stdin dhclient "
	  (shell-quote-argument internet-ethernet-interface)))

(defconst internet--kill-dhclient-command
  '"sudo --stdin pkill dhclient"
  "Command to kill dhclient process.")

;;;;;;;;;;;;;;;;;;;;;;
;; openvpn commands ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun internet--openvpn-connect-command (vpn)
  "Return a command to connect to a VPN using openvpn.

VPN is the vpn to connect to."

  (concat "sudo --stdin openvpn --config "
	  (concat
	   (shell-quote-argument internet-openvpn-config-directory)
	   (shell-quote-argument vpn)
	   ".ovpn")))

(defconst internet--kill-openvpn-command
  '"sudo --stdin pkill openvpn"
  "Command to kill openvpn process.")

;;;;;;;;;;;;;;;;;;;;;;;;;
;; ethernet connection ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet-ethernet-connect ()
  "Connect to the internet with ethernet."
  (interactive)

  (let ((process-buffer "internet-ethernet-connect")

	(command (concat (internet--ip-link-ethernet-up-command)
			 " && "
			 (internet--dhclient-get-ethernet-ip-address-command))))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

(defun internet-ethernet-disconnect ()
  "Disconnect ethernet internet connection."
  (interactive)

  (let ((process-buffer "internet-ethernet-disconnect")

	(command (concat internet--kill-dhclient-command
			 " && "
			 (internet--ip-link-ethernet-down-command))))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ethernet and openvpn connection ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet-ethernet-openvpn-connect (vpn)
  "Connect to the internet with ethernet.

VPN is the name of the vpn to connect with."
  (interactive

   (list (completing-read "VPN to connect with: "
			  (internet--files-without-extension-in-directory
			   internet-openvpn-config-directory ".ovpn")
			  nil
			  t)))

  (let ((process-buffer "internet-ethernet-openvpn-connect")

	(command (concat (internet--ip-link-ethernet-up-command)
			 " && "
			 (internet--dhclient-get-ethernet-ip-address-command)
			 " && "
			 (internet--openvpn-connect-command
			  (shell-quote-argument vpn)))))

    (async-shell-command command process-buffer process-buffer)))

(defun internet-ethernet-openvpn-disconnect ()
  "Disconnect ethernet internet connection."
  (interactive)

  (let ((process-buffer "internet-ethernet-openvpn-disconnect")

	(command (concat internet--kill-openvpn-command
			 " && "
			 internet--kill-dhclient-command
			 " && "
			 (internet--ip-link-ethernet-down-command))))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wireless network configuration ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet-add-wireless-configuration
    (network-name network-ssid network-password)
  "Add a wpa_supplicant configuration file.

NETWORK-NAME is the name that will be given to the wpa_supplicant
configuration file with a .conf suffix added.  It should be
alpanumeric.
NETWORK-SSID is the ssid of the network.
NETWORK-PASSWORD is the password of the network."
  (interactive

   (list (read-string "Network name (only alphanumeric characters): ")
	 (read-string "Wifi network SSID: ")
	 (read-passwd "Wifi network password: " t)))

  (let ((command (concat
		  "sudo --stdin "
		  "sh -c '"
		  "wpa_passphrase "
		  (shell-quote-argument network-ssid)
		  " "
		  (shell-quote-argument network-password)
		  " > "
		  (concat
		   (shell-quote-argument internet-wpa-supplicant-config-directory)
		   (shell-quote-argument network-name)
		   ".conf")
		  "'"))

	(process-buffer "internet-add-wireless-configuration"))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))

    (set-process-sentinel
     (get-process (get-buffer-process process-buffer))
     'internet--sentinel-add-wireless-configuration)))

(defun internet--sentinel-add-wireless-configuration (_process string)
  "Outputs the name and status of a process.

_PROCESS is the process to report on.
STRING is the status of PROCESS."

  (message "%s %s"
	   "internet-add-wireless-configuration"
	   (string-trim-right string)))

(defun internet-remove-wireless-configuration (configuration-file)
  "Remove a wpa_supplicant configuration file.

CONFIGURATION-FILE is the wpa_supplicant configuration file to
remove."
  (interactive

   (list (completing-read
	  "wpa_supplicant configuration file to remove: "
	  (directory-files
	   (shell-quote-argument internet-wpa-supplicant-config-directory))
	  nil
	  t)))

  (let ((command
	 (concat
	  "sudo --stdin rm "
	  (shell-quote-argument internet-wpa-supplicant-config-directory)
	  (shell-quote-argument configuration-file)))

	(process-buffer "internet-remove-wireless-configuration"))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;; wireless connection ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet-wireless-connect (network-name)
  "Connect to a wireless network.

NETWORK-NAME is the name of the network wpa_supplicant config file
without the suffix."
  (interactive

   (list (completing-read "Wifi network to connect to: "
			  (internet--files-without-extension-in-directory
			   internet-wpa-supplicant-config-directory ".conf")
			  nil
			  t)))

  (let ((process-buffer "internet-wireless-connect")

	(command (concat (internet--rfkill-unblock-command)
			 " && "
			 (internet--ip-link-wireless-up-command)
			 " && "
			 (internet--wpa-supplicant-connect-command
			  (shell-quote-argument network-name))
			 " && "
			 (internet--dhclient-get-wireless-ip-address-command))))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

(defun internet-wireless-disconnect ()
  "Disconnect from wireless network."
  (interactive)

  (let ((process-buffer "internet-wireless-disconnect")

	(command (concat internet--kill-dhclient-command
			 " && "
			 internet--kill-wpa-supplicant-command
			 " && "
			 (internet--ip-link-wireless-down-command)
			 " && "
			 (internet--rfkill-block-command))))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wireless openvpn connection ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet-wireless-openvpn-connect (wireless-network vpn)
  "Connect to wireless network and vpn.

WIRELESS-NETWORK is the name of the wireless network to connect to.
VPN is the name of the vpn to connect to."
  (interactive

   (list (completing-read "Wifi network to connect to: "
			  (internet--files-without-extension-in-directory
			   internet-wpa-supplicant-config-directory ".conf")
			  nil
			  t)
	 (completing-read "VPN to connect to: "
			  (internet--files-without-extension-in-directory
			   internet-openvpn-config-directory ".ovpn")
			  nil
			  t)))

  (let* ((process-buffer "internet-wireless-openvpn-connect")

	 (command (concat (internet--rfkill-unblock-command)
			  " && "
			  (internet--ip-link-wireless-up-command)
			  " && "
			  (internet--wpa-supplicant-connect-command
			   (shell-quote-argument wireless-network))
			  " && "
			  (internet--dhclient-get-wireless-ip-address-command)
			  " && "
			  (internet--openvpn-connect-command vpn))))

    (async-shell-command command process-buffer process-buffer)))

(defun internet-wireless-openvpn-disconnect ()
  "Disconnect from vpn and wireless network."
  (interactive)

  (let ((process-buffer "internet-wireless-openvpn-disconnect")

	(command (concat internet--kill-openvpn-command
			 " && "
			 internet--kill-dhclient-command
			 " && "
			 internet--kill-wpa-supplicant-command
			 " && "
			 (internet--ip-link-wireless-down-command)
			 " && "
			 (internet--rfkill-block-command))))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;; option list builder ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet--files-without-extension-in-directory
    (directory file-extension)
  "Return list of files with a specific file extension removed.

DIRECTORY is the directory to search.
FILE-EXTENSION is the file extension to search for and remove from
results."

  (let ((files-with-extension
	 (seq-filter
	  (lambda (x) (string-suffix-p file-extension x))
	  (directory-files directory))))

    (mapcar
     (lambda (x) (string-remove-suffix file-extension x))
     files-with-extension)))

(provide 'internet)
;;; internet.el ends here
