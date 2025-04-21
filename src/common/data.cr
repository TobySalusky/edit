import csv;
import rl;
import std;
// import element;

struct Data {
    char^ file_path;
    char^ name;
    SpreadSheet spreadsheet;
    List<char^> headers;
    List<SpreadSheetRow> data;

    construct(char^ file_path) {
        SpreadSheet spreadsheet = ParseSpreadSheet(Path(file_path));
        char^ name = c:strdup(c:GetFileNameWithoutExt(file_path));
        println(t"Imported data '{name}':");
        spreadsheet.print();
        return {
            .name = name,
            .spreadsheet = spreadsheet,
            .headers = spreadsheet.headers,
            .data = spreadsheet.rows,
            .file_path = file_path
        };
    }

    void Unload() {
        // TODO
    }
}

bool ListContainsString(List<char^>& list, char^ str) {
    for (let& item in list) {
        if (str_eq(item, str)) {
            return true;
        }
    }
    return false;
}

bool StringContains(char^ str, char^ substr) {
    return c:strstr(str, substr) != NULL;
}
