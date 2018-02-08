# -*- encoding : utf-8 -*-
require 'testing'
Testing Dao::Conducer do
  testing 'that dao has a root' do
    assert{ Dao.respond_to?(:root) }
    assert{ Dao.root }
  end

  testing 'that dao can build a mock controller' do
    controller = assert{ Dao.mock_controller }
    assert{ controller.url_for '/' }
  end

  testing 'that dao can mark the current_controller' do
    assert{ Dao.current_controller = Dao.mock_controller }
  end

  testing 'that dao can pre-process parameters' do
    params = Map.new( 
      'dao' => {
        'foos' => {
          'k' => 'v',
          'array.0' => '0',
          'array.1' => '1'
        },

        'bars' => {
          'a' => 'b',
          'hash.k' => 'v',
          '~42' => 'foobar'
        }
      }
    )

    assert{ Dao.normalize_parameters(params) }

#require 'pry'
#binding.pry
    assert{ params[:foos].is_a?(Hash) }
    assert{ params[:foos][:k] == 'v' }
    assert{ params[:foos][:array] == %w( 0 1 ) }

    assert{ params[:bars].is_a?(Hash) }
    assert{ params[:bars][:a] == 'b' }
    assert{ params[:bars][:hash] == {'k' => 'v'} }
    assert{ params[:bars]['42'] == 'foobar' }
  end
end
