;;; internet.el --- Connect to the internet through a variety of methods -*- lexical-binding: t -*-

;; Copyright © 2020 Sean Hutchings <seanhut@yandex.com>

;; Author: Sean Hutchings <seanhut@yandex.com>
;; Maintainer: Sean Hutchings <seanhut@yandex.com>
;; Created: 2020-11-18
;; Keywords: comm, processes, terminals, unix
;; Version: 0.1.0-git
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

(defvar internet-ethernet-interface nil
  "Ethernet interface.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wireless connection configuration variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar internet-wpa-supplicant-config-directory nil
  "The directory where wpa_supplicant configuration files are located.")

(defvar internet-rfkill-device-id nil
  "Device ID for rfkill.")

(defvar internet-wireless-interface nil
  "Wireless interface.")

(defvar internet-wpa-supplicant-driver nil
  "Driver to be used with wpa_supplicant.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; openvpn connection configuration variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar internet-openvpn-config-directory nil
  "The directory where openvpn configuration files are located.")

;;;;;;;;;;;;;;;;;;;;;
;; rfkill commands ;;
;;;;;;;;;;;;;;;;;;;;;

(defconst internet--rfkill-unblock-command
  (concat "sudo --stdin rfkill unblock " internet-rfkill-device-id)
  "Command to soft unblock wireless device using rfkill.")

(defconst internet--rfkill-block-command
  (concat "sudo --stdin rfkill block " internet-rfkill-device-id)
  "Command to soft block wireless device using rfkill.")

;;;;;;;;;;;;;;;;;;;;;;
;; ip link commands ;;
;;;;;;;;;;;;;;;;;;;;;;

(defconst internet--ip-link-wireless-up-command
  (concat "sudo --stdin ip link set " internet-wireless-interface " up")
  "Command to set wireless interface to up using ip link.")

(defconst internet--ip-link-wireless-down-command
  (concat "sudo --stdin ip link set " internet-wireless-interface " down")
  "Command to set wireless interface to down using ip link.")

(defconst internet--ip-link-ethernet-up-command
  (concat "sudo --stdin ip link set " internet-ethernet-interface " up")
  "Command to set wireless interface to up using ip link.")

(defconst internet--ip-link-ethernet-down-command
  (concat "sudo --stdin ip link set " internet-ethernet-interface " down")
  "Command to set wireless interface to down using ip link.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wpa_supplicant commands ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun internet--wpa-supplicant-connect-command (network-name)
  "Return a command to connect to a wireless network using wpa_supplicant.

NETWORK-NAME is the network to connect to."

  (concat "sudo --stdin wpa_supplicant -B"
	  " -D" internet-wpa-supplicant-driver
	  " -c" (concat internet-wpa-supplicant-config-directory
			network-name
			".conf")
	  " -i" internet-wireless-interface))

(defconst internet--kill-wpa-supplicant-command
  '"sudo --stdin pkill wpa_supplicant"
  "Command to kill wpa_supplicant process.")

;;;;;;;;;;;;;;;;;;;;;;;
;; dhclient commands ;;
;;;;;;;;;;;;;;;;;;;;;;;

(defconst internet--dhclient-get-wireless-ip-address-command
  (concat "sudo --stdin dhclient " internet-wireless-interface)
  "Command to get ip address using dhclient.")

(defconst internet--dhclient-get-ethernet-ip-address-command
  (concat "sudo --stdin dhclient " internet-ethernet-interface)
  "Command to get ip address using dhclient.")

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
	  (concat internet-openvpn-config-directory vpn ".ovpn")))

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

	(command (concat internet--ip-link-ethernet-up-command
			 " && "
			 internet--dhclient-get-ethernet-ip-address-command)))

    (async-shell-command command process-buffer process-buffer)

    (save-excursion (delete-other-windows))))

(defun internet-ethernet-disconnect ()
  "Disconnect ethernet internet connection."
  (interactive)

  (let ((process-buffer "internet-ethernet-disconnect")

	(command (concat internet--kill-dhclient-command
			 " && "
			 internet--ip-link-ethernet-down-command)))

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

	(command (concat internet--ip-link-ethernet-up-command
			 " && "
			 internet--dhclient-get-ethernet-ip-address-command
			 " && "
			 (internet--openvpn-connect-command vpn))))
    
    (async-shell-command command process-buffer process-buffer)))

(provide 'internet)
;;; internet.el ends here
