require 'elasticsearch'
require 'sqlite3'
require 'jalalidate'

$db = SQLite3::Database.new 'data/people_ads.db'
columns, *rows = $db.execute2("select * from ads where id > ?", (IO.read("data/.last_exported_id") || '0').to_i);
prows= rows.map { |e| Hash[columns.zip e] };

def build_new_hash e
  converted_map = e.map do |k, v|
    [k, if k == 'date' then
          Date.parse(e['date'])
        else
          v.respond_to?(:chomp) ? v.chomp : v
        end]
  end.flatten
  added_pdate = Hash[*converted_map]
  pdate = JalaliDate.new(Date.parse(e['date'])).strftime("%Y%n%d").to_i
  added_pdate.merge({pdate: pdate, area: find_aread_code(e['phone'])})
end

$aread_codes= JSON.parse(IO.read(File.expand_path("../../data/area_codes.json", __FILE__)))

def find_aread_code phone
  begin
    area = $aread_codes.values.flatten.select { |e| e.values.flatten.include?(phone[0...4].to_i) }.first.keys.first
  rescue
  end if phone
  return area
end


#Setup elasticsearch and feed it to make it available on Kibana for easy exploration
client = Elasticsearch::Client.new();
# (1..13000).each{|e| begin client.delete(index: 'ads', type:'ads', id: e) rescue puts ' '; end}
prows.each do |e|
  client.index(index: 'ads', type: 'ads', id: e["id"], body: build_new_hash(e));
end;

IO.write("data/.last_exported_id", prows.sort_by { |e| e['id'] }.last['id'])


#(1..10000).each{|e| begin client.delete(index: 'ads', type:'ads', id: e) rescue puts ' '; end}

#Count words to build the dictionary and find the frequency of words in ads
words= rows.map { |e| e[2] }.map { |e| e.split(/[\s,،]/).select { |e| e.length>1 } }.flatten;
counts = words.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
IO.write('./data/words.json', JSON.pretty_generate(counts.sort_by { |_key, value| value }))


#elasticsearch query
query ={
    "query": {
        "bool": {
            "must": [
                {
                    "match": {
                        "ad_text": "نوساز"
                    }
                },
                {
                    "match": {
                        "ad_text": "فول"
                    }
                }
            ],
            "should": [
                {
                    "match": {
                        "ad_text": "لازم"
                    }
                },
                {
                    "match": {
                        "ad_text": "زیرقیمت"
                    }
                },
                {
                    "match": {
                        "ad_text": "زیر/ قیمت"
                    }
                },
                {
                    "match": {
                        "ad_text": "فوری"
                    }
                }
            ],
            "minimum_should_match": 1,
            "boost": 1
        }
    }
}