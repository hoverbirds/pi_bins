#!/usr/bin/python
'''
        Author: Igor Maculan - n3wtron@gmail.com
        A Simple mjpg stream http server
'''
#import cv2
#import Image
import threading
from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from SocketServer import ThreadingMixIn
import StringIO
import signal
import time
import sys
import math
#import cv2
import os
import io
from gi.repository import GExiv2
#from subprocess import call
import picamera
from urlparse import parse_qs

capture=None
last_image=None
image_lock = threading.Lock()
storageFolder='/home/pi/media'


def sigint_handler(signum, frame):
    print 'exiting application'
    exit(0)

signal.signal(signal.SIGINT, sigint_handler)

class PiCamRunner(threading.Thread):
    def run(self):
        global last_image
        with picamera.PiCamera() as camera:
            stream = io.BytesIO()
            counter = 0
            try:
                camera.resolution = (3280,2464) #picam 2
            except:
                camera.resolution = (2592,1944) #picam 1
            print "res %d, %d" % camera.resolution
            for foo in camera.capture_continuous(stream, format='jpeg'):
                # Truncate the stream to the current position (in case
                # prior iterations output a longer image)
                stream.truncate()
                stream.seek(0)
                counter += 1
                print "new capture %d" % counter
                with image_lock:
                    last_image=stream.getvalue()
                time.sleep(0.01)


class CamHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global last_image
        if self.path.endswith('.mjpg'):
            try:
                self.send_response(200)
                self.send_header('Content-type','multipart/x-mixed-replace; boundary=--jpgboundary')
                self.end_headers()
                while True:
                    with image_lock:
                        local_image = last_image
                    self.wfile.write("--jpgboundary")
                    self.send_header('Content-type','image/jpeg')
                    self.send_header('Content-length',str(len(local_image)))
                    self.end_headers()
                    self.wfile.write(local_image)
                    time.sleep(0.01)
                return
            except:
                return

        if self.path.endswith('.jpg'):
            try:
                with image_lock:
                    local_image = last_image
                self.send_response(200)
                self.send_header('Content-type','image/jpeg')
                self.send_header('Content-length',str(len(local_image)))
                self.end_headers()
                self.wfile.write(local_image)
                return
            except:
                return

        if 'capture' in self.path:
            try:
                with image_lock:
                    local_image = last_image
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                # Extract values from the query string
                path, _, query_string = self.path.partition('?')
                query = parse_qs(query_string)
                print("Received Geotag request for %s with query: %s" % (path, query))
                filename = query['filename'][0]
                lat = float(query['lat'][0])
                lon = float(query['lon'][0])
                alt = float(query['alt'][0])

                print("Received Geotag request with lat: %s lon: %s atl: %s " % (lat, lon, alt))
                imagepath = os.path.dirname(os.path.abspath(filename))
                if not os.path.exists(imagepath):
                    os.makedirs(imagepath)

                with open(filename, 'wb') as out:
                    out.write(local_image)
                exif = GExiv2.Metadata(filename)
                exif.set_gps_info(lon, lat, alt)
                exif.save_file()
                return
            except:
                return


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
        """Handle requests in a separate thread."""

def main():
        global capture
        capture = PiCamRunner()
        capture.daemon = True
        try:
                capture.start()
                server = ThreadedHTTPServer(('', 5555), CamHandler)
                print "server started"
                server.serve_forever()
        except KeyboardInterrupt:
                print "cleanup"
                capture.join()
                server.socket.close()

if __name__ == '__main__':
        main()


