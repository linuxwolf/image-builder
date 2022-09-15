LIBDIR?=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(LIBDIR)/config.mk
include $(LIBDIR)/image.mk
