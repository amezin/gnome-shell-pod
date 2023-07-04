#!/usr/bin/env gjs

'use strict';

imports.gi.versions.Gdk = '3.0';
imports.gi.versions.Gtk = '3.0';

const System = imports.system;
const { Gio, Gtk } = imports.gi;

class DBusApi {
    TestMethod() {
        return 'OK';
    }
}

const interface_xml = `
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
    "http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">

<node>
    <interface name="gnome.shell.pod.test.Test">
        <method name="TestMethod">
            <arg type="s" direction="out"/>
        </method>
    </interface>
</node>
`;

const dbus_api = Gio.DBusExportedObject.wrapJSObject(interface_xml, new DBusApi());
dbus_api.export(Gio.DBus.session, '/gnome/shell/pod/test');

const app = new Gtk.Application({ application_id: 'gnome.shell.pod.test' });

app.connect('startup', Function());
app.connect('activate', Function());

app.run([System.programInvocationName].concat(ARGV));
