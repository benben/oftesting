# oftesting - automatic cross-platform testing suite for openFrameworks

See results here: http://videosynthesis.net/oftesting

## Installation:

### Prequisites

* Ruby >= 1.9.3p194
* Vagrant >= 1.0.5
* VirtualBox >= 4.1.22
* git >= 1.7.9.5

(TODO)

## Commands:

``` bash
rake test # compile everything on all platforms
rake test['only on osx 10.8','mac'] # give the testrun a name and compile everything only on osx

rake retest[last,vagrant-osx-10.8] # rerun all examples on OSX and update the last test
rake retest[last,vagrant-osx-10.8,allAddonsExample] # rerun the allAddonsExample on OSX and update the last test
rake retest[name-of-testrun,vagrant-osx-10.8,allAddonsExample] # rerun the allAddonsExample on OSX and update the test with the name 'name-of-testrun'

rake generate # generate html
rake deploy # deploy to gh-pages

rake create # creates and imports all boxes to vagrant specified in recipes
rake create[vagrant-archlinux-64bit] # creates and imports the box specified to vagrant
```

## License

(MIT License)
