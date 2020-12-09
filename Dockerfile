FROM alpine:latest

RUN apk update
RUN apk upgrade
RUN apk add emacs
RUN apk add git
RUN apk add make
RUN apk add texinfo
RUN apk add npm

RUN emacs --batch \
	--eval="(require 'package)" \
	--eval="(add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t)" \
	--eval="(package-initialize)" \
	--eval="(package-refresh-contents)" \
	--eval="(package-list-packages)" \
	--eval="(package-install 'elisp-lint)"

RUN npm install --global markdownlint-cli

COPY ./ /internet/

WORKDIR /internet

RUN make --makefile="docker-makefile"

