describe 'database' do
    def run_script(commands)
        raw_output = nil
        IO.popen("./build/main test.db", "r+") do |pipe|
            commands.each do |command|
                pipe.puts command
            end

            pipe.close_write

            # Read entire output
            raw_output = pipe.gets(nil)
        end
        raw_output.split("\n")
    end

    it 'inserts and retrieves a row' do
        result = run_script([
            "insert 1 user1 person1@example.com",
            "select",
            ".exit",
        ])
        expect(result).to match_array([
            "db > Executed.",
            "db > (1, user1, person1@example.com)",
            "Executed.",
            "db > ",
        ])
    end
    it 'prints error message when table is full' do
        script = (1..1401).map do |i|
            "insert #{i} user#{i} person#{i}@example.com"
        end
    script << ".exit"
    result = run_script(script)
    expect(result[-2]).to eq("db > Error: Table full.")
    end

    it 'allow inserting string with maximum length' do
        long_username = "a"*32
        long_email = "a"*255

        script = [
            "insert 1 #{long_username} #{long_email}",
            "select",
            ".exit",
        ]
        result = run_script(script)
        expect(result).to match_array([
            "db > Executed.",
            "db > (1, #{long_username}, #{long_email})",
            "Executed.",
            "db > ",
        ])
    end
    it 'throws error when inserting string with longer than maximum length' do
        long_username = "a"*33
        long_email = "a"*256

        script = [
            "insert 1 #{long_username} #{long_email}",
            "select",
            ".exit",
        ]
        result = run_script(script)

        print result

        expect(result).to match_array([
        "db > String is too long.",
        "db > Executed.",
        "db > ",
        ])
    end

    it 'throws error if is negative' do
        script = [
            "insert -1 a-fandino afandino@example.com",
            "select",
            ".exit",
        ]
        result = run_script(script)

        print result

        expect(result).to match_array([
        "db > ID must be positive.",
        "db > Executed.",
        "db > ",
        ])
    end
    it 'keeps data after closing connection' do 
        result1 = run_script([
            "insert 1 user1 person1@example.com",
            ".exit",
        ])
        expect(result1).to match_array([
            "db > Executed.",
            "db > ",
        ])

        result2 = run_script([
            "select",
            ".exit",
        ])
        expect(result2).to match_array([
            "db > (1, user1, person1@example.com)",
            "db > Executed.",            
            "db > ",
        ])

    end
      it 'prints constants' do
            script = [
              ".constants",
              ".exit",
            ]
            result = run_script(script)
        
            expect(result).to match_array([
              "db > Constants:",
              "ROW_SIZE: 293",
              "COMMON_NODE_HEADER_SIZE: 6",
              "LEAF_NODE_HEADER_SIZE: 10",
              "LEAF_NODE_CELL_SIZE: 297",
              "LEAF_NODE_SPACE_FOR_CELLS: 4086",
              "LEAF_NODE_MAX_CELLS: 13",
              "db > ",
            ])
        end
        it 'prints an error message if there is a duplicate id' do
              script = [
                "insert 1 user1 person1@example.com",
                "insert 1 user1 person1@example.com",
                "select",
                ".exit",
              ]
              result = run_script(script)
              expect(result).to match_array([
                "db > Executed.",
                "db > Error: Duplicate key.",
                "db > (1, user1, person1@example.com)",
                "Executed.",
                "db > ",
              ])
            end
    end

