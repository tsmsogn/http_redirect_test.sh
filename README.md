# http_redirect_test  

Shell script for testing HTTP redirect

## Usage

### Tests 200

```
% ./http_redirect_test.sh --status 200 http://httpstat.us/200
% echo $?
0
```

### Tests 30X

- 300

```
% http_redirect_test.sh http://httpstat.us/300
% echo $?
0
```

- 301,302,303

```
% http_redirect_test.sh http://httpstat.us/301 http://httpstat.us
% echo $?
0
```

### Tests 30X with status code

- 300

```
% http_redirect_test.sh --status 300 http://httpstat.us/300
% echo $?
0
```

- 301,302,303

```
% http_redirect_test.sh --status 301 http://httpstat.us/301 http://httpstat.us
% echo $?
0
```

## License 

The MIT License

## Author

@tsmsogn

## Thanks

Inspired by http_redirect_test written Ruby. https://github.com/eightbitraptor/http_redirect_test
