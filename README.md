Water Demo
==========

This is a port of Evan Wallace's [Water Demo](http://madebyevan.com/webgl-water/) from WebGL to Unity.

Motivation
----------

I ported this as an exercise to investigate different caustics implementations.  Having surveyed research papers on real-time caustics, I believe Evan's work supercedes many published algorithms in terms of simplicity and performance and is suitable for publication.

Requirements
------------

* Unity 2018.2.17f1

Implementation Notes
--------------------

This is a pretty faithful reproduction of Evan's demo.  As such there are a number of cases where it deviates from Unity's conventions.

For instance, the shader that renders the sphere has variable `sphereCenter`, so the sphere rendering object is expected to located at the origin and if you change that, it probably will not look right.

The light direction is provided to shaders as a vector.  It doesn't use Unity's lighting at all.

The models' vertices do not have UV coordinates.  For instance the cube's minimum and maximum model position are (-1, -1, -1) and (1, 1, 1), so any point on its surface is often just mapped directly to a UV coordinate [0, 1]^2 by transforming the point p by `p * 0.5 + 0.5`.  This works fine for the purposes of the demo, but one would probably want to switch to UV coordinates in the future.

A lot of this is smoke and mirrors. The cube knows where the sphere is, so it renders its shadow. Great for a tech demo, but if you want to allow for multiple spheres or other objects, this will need to be reformulated significantly.

Bugs
----

See the `todo.org` file.

License
-------

This project is released under the MIT license.
