require_relative 'spec_helper'

describe '#find_amplify_meta_json' do
  context 'when amplify-meta.json is found' do
    it 'returns the correct file path' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(/amplify-meta\.json$/).and_return(true)

      result = AmplifyOpenSearchBackfill::Introspector.new(
        api_name: 'client',
        model_name: 'widget'
      ).find_amplify_meta_json
      expect(result).to match(/amplify-meta\.json$/)
    end
  end

  context 'when amplify-meta.json is not found' do
    it 'raises an error' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(/amplify-meta\.json$/).and_return(false)

      expect do
        result = AmplifyOpenSearchBackfill::Introspector.new(
          api_name: 'client',
          model_name: 'widget'
        ).find_amplify_meta_json
      end.to raise_error(RuntimeError,
                         'amplify-meta.json not found in the current directory or any parent directories.')
    end
  end
end
