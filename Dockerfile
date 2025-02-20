# This is a multi-stage setup
# This section is used to create the necessary files that the final image
FROM node:16-alpine as build 
# Creates this '/app' path in the container and 
# makes this the directory where all other commands below it will run
WORKDIR /app
# Takes the package*.json files in the source code you downloaded and
# copies it to the current directory (in this case /app)
# In this case, there's a package.json file 
# (which is where you setup your scripts and node dependencies)
# And there's a package-lock.json file
# (which is where you "lock" the specific versions of the dependencies
#  super important to do so there isn't any incompatibility issues!)
COPY package*.json ./
# This NPM command installs any dependencies that the application needs
# the dependencies are definied in the package*.json file
RUN npm ci
# Once the dependencies are installed, copy the entire application folder
# to the container
COPY . .
# This NPM command runs the build script defined in the package.json file
# which is "vite build" (basically packages up the final application)
RUN npm run build


# Now that the application is nicely packaged, 
# it's time to make a clean(er) final container image!
FROM node:16-alpine
# Again create and set the working path to be '/app'
WORKDIR /app
# This NPM command is actually installing another dependency (serve)
# which is needed in the final image to serve the files
RUN npm install -g serve
# This is where the beauty of multi-stage setup shines, 
# this command takes the 'dist' folder  from the image above (labeled build)
# and places it in the app folder for this current image
# it ensures that we're only copying files that are necessary for this
# final image (thus making it smaller and cleaner)
COPY --from=build /app/dist /app
# Both ENV commands below are setting environment variables within the container
ENV VITE_API_BASE_URL=http://abdd3274ed8f34c65ae0e00009bd6a42-1396619251.us-east-1.elb.amazonaws.com:5000/api
ENV PORT=5001
ENV NODE_ENV=production
# Like in the backend Dockerfile, we want to expose this container via a particular
# port, note that it is not the same port number (make sure they aren't otherwise we
# will have issues starting up our containers!)
EXPOSE 5001
# After everything is setup, we run this command (via the dependency we installed via npm
# earlier) to start serving the application. These are generally going to be commands we
# would/could run in the terminal of a virtual machine.
CMD ["serve", "-s",".","-l","5001"]
