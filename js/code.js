function spaceOnHead(line) {
    var result = 0;
    while (line.charCodeAt(result) == 32) result ++;
    return result;
}