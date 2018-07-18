+++
# Date this page was created.
date = 2018-06-13T00:00:00

# Project title.
title = "Adding Jupyter Notebooks to Hugo/Blogdown Sites 2.0"

# Project summary to display on homepage.
summary = "How to add a Jupyter notebook into a Hugo or R Blogdown site."

# Tags: can be used for filtering projects.
# Example: `tags = ["machine-learning", "deep-learning"]`
tags = ["forecasting","r"]

# Optional external URL for project (replaces project detail page).
external_link = ""

# Does the project detail page use math formatting?
math = true

# Optional featured image (relative to `static/img/` folder).
[header]
#image = "headers/bubbles-wide.jpg"
#caption = "My caption :smile:"

+++

Jupyter notebook is an awesome way to share your Python data science projects. I have always loved the look and feel of Jupyter. So it makes sense that when I started my R Blogdown site powered on Hugo, I was dissapointed to find no built in functionality for support Jupyter Notebooks.

Luckily, after much Google searching and playing around with Jupyter's CSS style sheet, I was able to find a solution that I like. As an example, this article was written using the method I'm about to go through.

## Converting the Jupyter Notebook to Basic HTML

The first step is to convert your Jupyter notebook to html. It may be tempting to simply use Jupyter's built in funcitonality under __file__ > __download as__ > __HTML__, however we need to use the basic template for html, so we will use `nbconvert` from the command line.

Open up your command prompt, navigate to the folder that contains your jupyter notebook, and enter the following:
```bat
jupyter nbconvert notebook.ipynb --to html --template basic
```
Where 'notebook.ipynb' is the name of the Jupyter notebook you want to convert. The Notebook will be converted into a basic html form, ready for use in your website.

## Adding CSS Styling

Now that we have the html of our workbook we need to point it to the correct CSS style sheet so it will have the same Jupyter look when we embed it in our website. I created a CSS file by simply using Jupyter's default CSS stylesheet and stripping away any unnessecary CSS from it. You can download the file [here](https://github.com/jdglaser/blogdown_source/blob/master/jupyterCustom.css). Place the file in your Hugo site's __static__ > __css__ folder.

Next, open up that html version of the Jupyter notebook we downloaded earlier in any code editor. You can even use R studio if you'd like. Paste the following at the very top of the html document, before any of the html tags:

```
+++
date = YYYY-mm-ddTHH:MM:SS

title = "my title"

whatever other YAML is required by your specific Blogdown/Hugo theme.
+++

<link href="/css/jupyterCustom.css" rel="stylesheet" type="text/css">

```

Now save your edited html jupyter notebook file in the content section of your Hugo site. Build your site. And you should see a neatly rendered Jupyter notebook as a Hugo blogpost. All features in Jupyter should work, inlcuding math (only works if your theme supports math expressions for markdown such as [Hugo Academic](https://themes.gohugo.io/academic/)), python code, R code, and images.

## Example


```python
import pandas as pd
```


```python
pd.DataFrame({"Column A":[1,2,3,4,5],"Column B":[True, False, False, True, True],"Column C":["Dog","Cat","Mouse","Cow","Pig"]
             ,"Column D":[2.77,3.48,5.44,7.13,3.14]})
```




<div>
<style>
    .dataframe thead tr:only-child th {
        text-align: right;
    }

    .dataframe thead th {
        text-align: left;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Column A</th>
      <th>Column B</th>
      <th>Column C</th>
      <th>Column D</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1</td>
      <td>True</td>
      <td>Dog</td>
      <td>2.77</td>
    </tr>
    <tr>
      <th>1</th>
      <td>2</td>
      <td>False</td>
      <td>Cat</td>
      <td>3.48</td>
    </tr>
    <tr>
      <th>2</th>
      <td>3</td>
      <td>False</td>
      <td>Mouse</td>
      <td>5.44</td>
    </tr>
    <tr>
      <th>3</th>
      <td>4</td>
      <td>True</td>
      <td>Cow</td>
      <td>7.13</td>
    </tr>
    <tr>
      <th>4</th>
      <td>5</td>
      <td>True</td>
      <td>Pig</td>
      <td>3.14</td>
    </tr>
  </tbody>
</table>
</div>




```python
print("Hello World!")
```

    Hello World!
    


```python
4 + 6 + 10 + 3.7
```




    23.7


```python
print("The Fox is in the bowl, if he gets out then he will run")
```

    The Fox is in the bowl, if he gets out then he will run
    
This is an $\alpha + 10 = \beta + 5$ inline math expression.

This is not:
$$\alpha + \frac{\gamma}{1 + \sigma} = \sum{x_i}$$

You can also put pictures in the notebook.

__Markdown Code:__
```html
<img src="./JupyterNotebookInRBlogdown/img.png" width="20%">
```

__Result:__
<img src="./JupyterNotebookInRBlogdown/img.png" width="20%">

Note: All images and image folders must also be in your static folder of your site.

So there you have it! An easy and quick way to add Jupyter notebooks to your Blogdown/Hugo site without sacrificing the Jupyter notebook style.
