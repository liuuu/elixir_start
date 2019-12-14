```
iex -S mix
```

```
cities = ["Singapore", "Monaco", "Vatican City", "Hong Kong", "Macau"]

Enum.map cities, &(m.get_temperature(&1))
```
