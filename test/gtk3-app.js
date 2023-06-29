#!/usr/bin/env gjs

'use strict';

imports.gi.versions.Gdk = '3.0';
imports.gi.versions.Gtk = '3.0';

const System = imports.system;
const { Gio, Gtk } = imports.gi;

const TEST_DIR = Gio.File.new_for_commandline_arg(System.programInvocationName).get_parent();

const app = new Gtk.Application();

app.connect('startup', () => {});
app.connect('activate', () => {});

app.run([System.programInvocationName].concat(ARGV));
