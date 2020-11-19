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

(provide 'internet)
;;; internet.el ends here
