# image_generator

A simple Flutter project

## Getting Started

An API that handles the reconstruction is needed, and for that I used my own python API (available at https://github.com/murilo-marian/AI-Image-Reconstruction).

You then need to point the HTTP request to the IP and port of access for the API, you can change it at AI-Image-Generation-App/lib/screens/form_screen.dart, in the "final uri = Uri.parse("http://172.16.2.77:5000/run-genetic-algorithm");" line.
