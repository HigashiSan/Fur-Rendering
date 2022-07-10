# Fur-Rendering
My survey on fur rendering in unity URP.

Up to now, I have tried to render fur in two ways, both are based on geometry shader.And surport shadows and simple lighting calculation.

One is to enlarge the model several times along the normal vector, then discard some parts by a texture which defines the fur area:

![image](https://user-images.githubusercontent.com/56297955/178151308-bdd2f33b-1b1e-4fc1-b38a-907a7a34b044.png)   

![image](https://user-images.githubusercontent.com/56297955/178151323-a30d9a1b-f0cc-4899-a603-1efff1b864ee.png)

And can also set the layers which define how many times the model enlarged.

![image](https://user-images.githubusercontent.com/56297955/178152087-7bf5b10e-2bf5-4c63-81ec-49e2fd8f89f7.png)

The other way is to generate new quad fron current mesh using geometry shader.Then use a fur texture's alpha channel to define the shape of the fur.
Here is the picture I found in NVIDIA's talk:

![image](https://user-images.githubusercontent.com/56297955/178152153-f4799f89-104c-4621-8ca6-1dacf0dca591.png)

![Screenshot 2022-07-10 214926](https://user-images.githubusercontent.com/56297955/178152252-558c1c08-802d-42d9-b86a-42ff4fe9c943.png)

This way rely on the mesh of the number of triangles of the model. So I also use Tessellation Shader to increase the density of the hair and add the move to the fur.



https://user-images.githubusercontent.com/56297955/178152900-cf58b9dc-d654-4568-b02b-88a110e72b88.mp4



https://user-images.githubusercontent.com/56297955/178152931-e162ba9d-6a11-4478-93c7-3bdfee330e7b.mp4

