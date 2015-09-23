January2012 is the third formal milestone for the Tower of Psych project.  It corresponds to the repository tag called January2012:
```
http://tower-of-psych.googlecode.com/svn/tags/January2012
```

[Documentation contemporary with January2012](http://tower-of-psych.googlecode.com/svn-history/r270/documentation/html/index.html) is available.

January2012 will receive bug fixes, but new API and feature changes will go in the trunk, to be included in a later milestone.



### Overview ###
January2012 implements two features: classification for spatial data, and aggregation of objects into "ensembles" for doing operations in batches.

### Classification ###
January2012 implements classes for modeling and classifying spatial data (or any data treated as spatial).

  * topsDimension models discrete, finite spatial dimensions
  * topsSpace aggregates Dimensions to define a discrete, finite space
  * topsRegion models a region within a Space
  * topsClassification classifies spatial data, based on Regions within a Space

See demos/demoRegion.m and demos/demoClassification.m.

topsStateMachine makes use of topsClassification.  Each state may have its own Classification, allowing it to respond to inputs in a state-dependent way.  This functionality supplements state input functions.

StateDiagramGrapher can peek at the Classifications used by topsStateMachine.  Since the outputs of a Classification are known in advance, peeking allows StateDiagramGrapher to produce rich graphs.

### Ensembles ###
January2012 also implements object grouping behavior with "ensembles".

  * topsEnsemble aggregates arbitrary objects and does member access and method invocation in batches.

It is up to to users to create ensembles whose members have methods or properties in common, so that they can be treated uniformly.

Aggregated objects don't have to know anything about topsEnsemble, or how aggregation is accomplished.  An aggregated object can be identified uniquely from its topsEnsemble instance, plus an index into the ensemble.  topsEnsemble returns an object's index when the object is added to the ensemble with addObject(), and from the containsObject() method.