Installing Tower of Psych is easy, because it's pure Matlab.  You just
  * Get the files.
  * Add them all to your Matlab path.

Here's how.



## Get the Files ##

#### Subversion ####
The easiest way to get Tower of Psych and keep the files up to date is with the [Subversion](http://svnbook.red-bean.com/en/1.7/svn.intro.whatis.html) tool.  Subversion is free.

Here's the Subversion "checkout" command for Tower of Psych Version 1:
```
svn checkout http://tower-of-psych.googlecode.com/svn/tags/Version_1 tower-of-psych
```

#### Download ####
If you can't use Subversion, you can download a [static copy of Tower of Psych](http://tower-of-psych.googlecode.com/files/tower-of-psych-r421.zip).

There are [more downloads](http://code.google.com/p/tower-of-psych/downloads/list) here at the project site.

## Get Started ##
Once you have all the files, add them to your Matlab path.  From the Matlab desktop, click on `File -> Set Path... -> Add with Subfolders` and choose the folder where you saved Tower of Psych.

You can get started with Tower of Psych by reading about [ComponentsAndConcepts](ComponentsAndConcepts.md) or by trying demos which are included with the code.
  * `tower-of-psych/demos/` contains simple demos for Tower of Psych components
  * `tower-of-psych/demos/tasks/` contains a few complex demos that integrate components into working tasks

## Optional ##
Tower of Psych can work with a couple of external projects for advanced functionality.  These are not required for running demos and making tasks.

#### Graphing ####
To use the graphing capabilities of Tower of Psych, you must install [GraphViz](http://www.graphviz.org/) on your computer.  GraphViz is a free tool for generating diagrams, flow charts, and the like.

The graphing tools and demos are in
```
tower-of-psych/utilities/graphing/
```

#### Testing ####
To run the Tower of Psych unit tests, you must install the [MATLAB xUnit Test Framework](http://www.mathworks.com/matlabcentral/fileexchange/22846-matlab-xunit-test-framework).

Once this is installed, you can run all of the Tower of Psych unit tests from Matlab, like this:
```
cd tower-of-psych
topsRunTests();
```