# Use > instead of a tab as recipe prefixes.
.RECIPEPREFIX = >

###########
# Variables
###########

# Files
name = internet
texinfo = $(name).texinfo
info_file = $(name).info
html_directory = docs/

# Arguments
rm_options = -r -f

# Docker
image-tag = internet-el

#######
# Rules
#######

.PHONY: all
all : docker-makefile documentation

.PHONY: docker-makefile
docker-makefile :
> docker build -t $(image-tag) .

documentation : documentation-info documentation-html

documentation-info : $(texinfo)
> makeinfo --output=$(info_file) $(texinfo)

documentation-html : $(texinfo)
> rm $(rm_options) $(html_directory)
> mkdir $(html_directory)
> makeinfo --html --output=$(html_directory) $(texinfo)

.PHONY: clean
clean :
> docker image rm $(image-tag)
