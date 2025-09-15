---
title: предыстория(origin story)
parent: blog
nav_order: 10
---

{% capture en_content %}
{% include_relative {{page.path|split:'/'|last|split:'.'|first}}/README_EN.md %}
{% endcapture %}
<details markdown="1">
  <summary>EN</summary>
  {{ en_content | markdownify }}
</details>


{% include_relative {{page.path|split:'/'|last|split:'.'|first}}/README.md %}

