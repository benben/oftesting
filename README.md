# oftesting - automatic cross-platform testing suite for openFrameworks

See results here: http://oftesting.benjaminknofe.com/

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
rake test['PR 1838'] # name a testrun
rake test['only on osx 10.8','mac'] # give the testrun a name and compile everything only on boxes with 'mac' in the name
rake test['PR 1716 on all linux machines','os:linux'] # run named testrun on all linux machines
rake test['videoPlayer Ubuntu test','Ubuntu','videoPlayerExample'] # give the testrun a name and compile the videoPlayerExample only on ubuntu boxes

rake retest[last,'Debian 6.0.5 GNOME 32bit'] # rerun all examples on Debian and update the last test
rake retest[last,'Debian 6.0.5 GNOME 32bit',allAddonsExample] # rerun the allAddonsExample on Debian and update the last test
rake retest[name-of-testrun,'Debian 6.0.5 GNOME 32bit',allAddonsExample] # rerun the allAddonsExample on Debian and update the test with the name 'name-of-testrun'

rake open['Arch Linux GNOME 32bit'] # open box with gui and provisioned OF for inspection

rake generate # generate html
rake deploy   # deploy to gh-pages

rake show_head        # shows current HEAD of the openFrameworks source
rake update_source    # updates the openFrameworks source specified in config.yml
rake prepare_pr[1716] # prepare an extra branch where the specified PR is merged

rake create # creates and imports all boxes to vagrant specified in recipes
rake create[vagrant-archlinux-64bit] # creates and imports the box specified to vagrant
```

## License

(MIT License)
