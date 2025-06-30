import std;
import map;
import list;

struct SpreadSheetRow {
    // SpreadSheet& sheet;
    // List<char^> entries;
    StrMap<char^> entries;

    char^ get(char^ label) {
        if (!entries.has(label)) { panic(t"SpreadSheetRow did not contain entry: '{label}'"); }
        return entries.get(label);
    }

    int get_int(char^ label) -> c:atoi(this.get(label));
    float get_float(char^ label) -> c:atof(this.get(label));

    void print_as_row() {
        for (int i = 0; i != entries.size; i++) {
            printf("%s", t"{entries.values[i]}{(i == entries.size - 1) ? "\n" | ","}");
        }
    }

    void print_self() {
        for (int i = 0; i != entries.size; i++) {
            println(t"{entries.keys[i]}:\t{entries.values[i]}");
        }
    }
}
struct SpreadSheet {
    List<char^> headers;
    List<SpreadSheetRow> rows;

    SpreadSheetIter iter() -> {
        .sheet = this,
        .i = 0,
    };

    void print_headers() {
        for (int i = 0; i != headers.size; i++) {
            printf("%s", t"{headers.get(i)}{(i == headers.size - 1) ? "\n" | ","}");
        }
    }

    void print() {
        this.print_headers();
        for (let& row in rows) {
            row.print_as_row();
        }
    }
}

SpreadSheetRow ParseSpreadSheetRow(List<char^>& headers, string row) {
    let values = row.trim_split(",");

    StrMap<char^> entries = .();
    for (int i = 0; headers.size > i; i++) {
        entries.put(headers.get(i), values.at(i));
    }
    return { :entries };
}

SpreadSheet ParseSpreadSheet(Path p) {
    Strings lines = io.lines(p);
    defer lines.delete();
    
    string header = string(lines.at(0));
    let headers = header.trim_split(",").to_cstr_list();
    
    let rows = List<SpreadSheetRow>();
    for (int i = 1; i < lines.n; i++) {
        rows.add(ParseSpreadSheetRow(headers, string(lines.at(i))));
    }
    return { :headers, :rows };
}

struct SpreadSheetIter {
    SpreadSheet& sheet;
    int i;

    SpreadSheetIter iter() -> {
        :sheet,
        :i, // should be 0...
    };

    bool current_satisfies() {
        SpreadSheetRow row = sheet.rows.get(i);

        return true;
    }

    bool has_next() {
        while (sheet.rows.size > i) {
            if (this.current_satisfies()) {
                return true;
            }
            
            i++;
        }
        return false;
    }

    SpreadSheetRow& next() {
        return sheet.rows.get(i++);
    }
}
