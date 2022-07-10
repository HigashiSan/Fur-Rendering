# Fur-Rendering
My survey on fur rendering in unity URP.

Up to now, I have tried to render fur in two ways, both are based on geometry shader.

One is to enlarge the model several times along the normal vector, the discard some parts by a texture which defines the fur area:
![image](https://user-images.githubusercontent.com/56297955/178151308-bdd2f33b-1b1e-4fc1-b38a-907a7a34b044.png)       ![image](https://user-images.githubusercontent.com/56297955/178151323-a30d9a1b-f0cc-4899-a603-1efff1b864ee.png)


